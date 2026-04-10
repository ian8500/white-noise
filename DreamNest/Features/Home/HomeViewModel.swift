import Combine
import Foundation
import OSLog

private let homeLogger = Logger(subsystem: "com.dreamnest.app", category: "Home")

@MainActor
final class HomeViewModel: ObservableObject {
    private static let cryTriggeredPlaybackDuration: TimeInterval = 5 * 60
    private static let cryTriggeredSoundID = "white-noise"

    @Published var selectedSound: SoundDefinition
    @Published var volume: Float
    @Published var timerRemaining: TimeInterval = 0
    @Published var isPlaying = false
    @Published var warningBanner: String?
    @Published var cryModeEnabled: Bool
    @Published var cryDetectionThreshold: Float
    @Published private(set) var favoriteSoundIDs: Set<String>
    @Published private(set) var recentSoundIDs: [String]

    let catalog: [SoundDefinition]

    private var settings: AppSettings
    private let audio: AudioPlaybackControlling
    private let timer: SleepTimerScheduling
    private let store: SettingsStoring
    private let cryService: CryDetectionControlling
    private let systemVolume: SystemVolumeControlling
    private let safetyPolicy: NoiseSafetyPolicy
    private let cryResponseCoordinator: CryResponseCoordinator
    private var cancellables = Set<AnyCancellable>()
    private var playbackTask: Task<Void, Never>?
    private var cryMonitoringTask: Task<Void, Never>?
    private var playbackGeneration: Int = 0
    private var wasTimerRunning = false

    init(
        catalogService: SoundCatalogProviding,
        audio: AudioPlaybackControlling,
        timer: SleepTimerScheduling,
        store: SettingsStoring,
        cryService: CryDetectionControlling,
        systemVolume: SystemVolumeControlling? = nil,
        safetyPolicy: NoiseSafetyPolicy,
        cryResponseCoordinator: CryResponseCoordinator
    ) {
        self.catalog = catalogService.sounds
        self.audio = audio
        self.timer = timer
        self.store = store
        self.cryService = cryService
        self.systemVolume = systemVolume ?? NoOpSystemVolumeController()
        self.safetyPolicy = safetyPolicy
        self.cryResponseCoordinator = cryResponseCoordinator

        settings = store.load()
        selectedSound = catalogService.sound(id: settings.lastSoundID) ?? catalogService.sounds[0]
        volume = safetyPolicy.clamped(volume: self.systemVolume.currentVolume)
        cryModeEnabled = settings.cryResponse.enabled
        cryDetectionThreshold = settings.cryResponse.detectionThreshold
        favoriteSoundIDs = settings.favoriteSoundIDs
        recentSoundIDs = settings.recentSoundIDs

        bind()
        cryService.updateDetectionThreshold(settings.cryResponse.detectionThreshold)
        cryService.updateCooldown(settings.cryResponse.cooldown)
        startCryMonitoringIfNeeded()
    }

    deinit {
        playbackTask?.cancel()
        cryMonitoringTask?.cancel()
    }

    func quickStart() {
        startPlaybackSession(
            sound: selectedSound,
            micModeEnabled: cryModeEnabled,
            duration: settings.timer.duration,
            failurePrefix: "Playback failed"
        )
    }

    func stopPlayback() {
        playbackTask?.cancel()
        let generation = advancePlaybackGeneration()
        timer.cancel()
        Task {
            await audio.stop(fadeDuration: 0.3)
            guard generation == playbackGeneration else { return }
            isPlaying = false
        }
    }

    func setVolume(_ value: Float) {
        let clamped = safetyPolicy.clamped(volume: value)
        if safetyPolicy.shouldWarn(for: value) {
            warningBanner = "Volume capped for hearing safety guidance."
        }
        volume = clamped
        systemVolume.setSystemVolume(clamped)
        audio.updateVolume(clamped, rampDuration: 0.25)
        settings.lastVolume = clamped
        store.save(settings)
    }

    func selectSound(_ sound: SoundDefinition) {
        selectedSound = sound
        settings.lastSoundID = sound.id
        settings.recentSoundIDs.removeAll(where: { $0 == sound.id })
        settings.recentSoundIDs.insert(sound.id, at: 0)
        settings.recentSoundIDs = Array(settings.recentSoundIDs.prefix(5))
        recentSoundIDs = settings.recentSoundIDs
        store.save(settings)
    }

    func toggleFavorite(_ sound: SoundDefinition) {
        if settings.favoriteSoundIDs.contains(sound.id) {
            settings.favoriteSoundIDs.remove(sound.id)
        } else {
            settings.favoriteSoundIDs.insert(sound.id)
        }
        favoriteSoundIDs = settings.favoriteSoundIDs
        store.save(settings)
    }

    func isFavorite(_ sound: SoundDefinition) -> Bool {
        favoriteSoundIDs.contains(sound.id)
    }

    var recentSounds: [SoundDefinition] {
        recentSoundIDs.compactMap { id in
            catalog.first(where: { $0.id == id })
        }
    }

    func applyTimerPreset(minutes: Int) {
        settings.timer.duration = TimeInterval(minutes * 60)
        store.save(settings)
        updateRunningTimerForDurationChange(targetDuration: settings.timer.duration)
    }

    func adjustTimerDuration(minutesDelta: Int) {
        let currentMinutes = Int(settings.timer.duration / 60)
        let updatedMinutes = max(1, currentMinutes + minutesDelta)
        settings.timer.duration = TimeInterval(updatedMinutes * 60)
        store.save(settings)
        updateRunningTimerForDurationChange(targetDuration: settings.timer.duration)
    }

    var formattedTimerRemaining: String {
        Self.formatAsMinutesAndSeconds(timerRemaining)
    }

    var formattedTimerDuration: String {
        Self.formatAsMinutesAndSeconds(settings.timer.duration)
    }

    var timerCountdownTitle: String {
        if isPlaying, timerRemaining > 0 {
            return "\(formattedTimerRemaining) remaining"
        }
        return "Ready: \(formattedTimerDuration)"
    }

    var timerCountdownSubtitle: String {
        if isPlaying, timerRemaining > 0 {
            return "Playback stops automatically when countdown reaches 00:00."
        }
        return "Starts from \(formattedTimerDuration) when you begin a sleep session."
    }

    func toggleCryMode(_ enabled: Bool) {
        cryModeEnabled = enabled
        settings.cryResponse.enabled = enabled
        store.save(settings)

        cryMonitoringTask?.cancel()
        cryMonitoringTask = Task { [weak self] in
            guard let self else { return }
            if enabled {
                await requestPermissionAndStartCryService()
            } else {
                cryService.stop()
            }
        }
    }

    func setCryDetectionThreshold(_ value: Float) {
        let clamped = max(0.4, min(value, 0.95))
        cryDetectionThreshold = clamped
        settings.cryResponse.detectionThreshold = clamped
        cryService.updateDetectionThreshold(clamped)
        store.save(settings)
    }

    private func bind() {
        timer.statePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                guard let self else { return }
                timerRemaining = state.remaining
                let didTimerComplete = wasTimerRunning && !state.isRunning
                wasTimerRunning = state.isRunning

                if didTimerComplete {
                    let generation = advancePlaybackGeneration()
                    isPlaying = false
                    Task {
                        await self.audio.stop(fadeDuration: 0.3)
                        guard generation == self.playbackGeneration else { return }
                    }
                }

                let fadeGain = FadeCurve.gain(remaining: state.remaining, fadeDuration: state.fadeDuration)
                if state.isRunning {
                    audio.updateVolume(volume * fadeGain, rampDuration: 0.5)
                }
            }
            .store(in: &cancellables)

        cryService.detectionPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] signal in
                guard let self,
                      let action = cryResponseCoordinator.handle(
                          signal: signal,
                          isEnabled: settings.cryResponse.enabled,
                          settings: settings.cryResponse,
                          currentVolume: volume,
                          safetyPolicy: safetyPolicy
                      )
                else { return }

                setVolume(action.targetVolume)
                if isPlaying {
                    timer.extend(by: action.timerExtension)
                } else {
                    startCryTriggeredPlayback()
                }
                if action.shouldRecordEvent {
                    store.appendCryEvent(.init(confidence: signal.confidence))
                }
            }
            .store(in: &cancellables)

        systemVolume.volumePublisher
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] systemValue in
                guard let self else { return }
                let clamped = safetyPolicy.clamped(volume: systemValue)
                volume = clamped
                audio.updateVolume(clamped, rampDuration: 0.1)
                settings.lastVolume = clamped
                store.save(settings)
            }
            .store(in: &cancellables)
    }

    private static func formatAsMinutesAndSeconds(_ seconds: TimeInterval) -> String {
        let totalSeconds = max(0, Int(seconds.rounded()))
        let minutes = totalSeconds / 60
        let remainingSeconds = totalSeconds % 60
        return String(format: "%02d:%02d", minutes, remainingSeconds)
    }

    private func updateRunningTimerForDurationChange(targetDuration: TimeInterval) {
        guard isPlaying else { return }

        if timerRemaining <= 0 {
            timer.start(duration: targetDuration, fadeDuration: settings.timer.fadeDuration)
            return
        }

        let delta = targetDuration - timerRemaining
        if delta >= 0 {
            timer.extend(by: delta)
            return
        }

        let maxReduction = timerRemaining - 60
        let clampedReduction = max(delta, -maxReduction)
        timer.extend(by: clampedReduction)
    }

    private func startCryMonitoringIfNeeded() {
        guard settings.cryResponse.enabled else { return }
        cryMonitoringTask?.cancel()
        cryMonitoringTask = Task { [weak self] in
            await self?.requestPermissionAndStartCryService()
        }
    }

    private func requestPermissionAndStartCryService() async {
        let granted = await cryService.requestPermission()
        guard granted else {
            cryModeEnabled = false
            settings.cryResponse.enabled = false
            warningBanner = "Microphone permission is required for cry response mode."
            store.save(settings)
            return
        }

        do {
            cryService.updateDetectionThreshold(settings.cryResponse.detectionThreshold)
            cryService.updateCooldown(settings.cryResponse.cooldown)
            try cryService.start()
        } catch {
            cryModeEnabled = false
            settings.cryResponse.enabled = false
            warningBanner = "Unable to start cry detection: \(error.localizedDescription)"
            store.save(settings)
        }
    }

    private func startCryTriggeredPlayback() {
        let targetSound = catalog.first(where: { $0.id == Self.cryTriggeredSoundID }) ?? selectedSound
        startPlaybackSession(
            sound: targetSound,
            micModeEnabled: true,
            duration: Self.cryTriggeredPlaybackDuration,
            failurePrefix: "Cry response playback failed"
        )
    }

    private func startPlaybackSession(
        sound: SoundDefinition,
        micModeEnabled: Bool,
        duration: TimeInterval,
        failurePrefix: String
    ) {
        playbackTask?.cancel()
        let generation = advancePlaybackGeneration()
        playbackTask = Task { [weak self] in
            guard let self else { return }
            do {
                try audio.configureSession(micModeEnabled: micModeEnabled)
                try await audio.play(sound: sound, volume: safetyPolicy.clamped(volume: volume))
                guard !Task.isCancelled, generation == playbackGeneration else { return }
                timer.start(duration: duration, fadeDuration: settings.timer.fadeDuration)
                wasTimerRunning = true
                isPlaying = true
            } catch {
                guard !Task.isCancelled, generation == playbackGeneration else { return }
                isPlaying = false
                warningBanner = "\(failurePrefix): \(error.localizedDescription)"
                homeLogger.error("\(failurePrefix, privacy: .public): \(error.localizedDescription, privacy: .public)")
            }
        }
    }

    @discardableResult
    private func advancePlaybackGeneration() -> Int {
        playbackGeneration += 1
        return playbackGeneration
    }
}

private final class NoOpSystemVolumeController: SystemVolumeControlling {
    var volumePublisher: AnyPublisher<Float, Never> { Empty().eraseToAnyPublisher() }
    var currentVolume: Float { 0.35 }
    func setSystemVolume(_ value: Float) {}
}
