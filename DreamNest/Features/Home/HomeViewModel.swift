import Combine
import Foundation
import OSLog

private let homeLogger = Logger(subsystem: "com.dreamnest.app", category: "Home")

@MainActor
final class HomeViewModel: ObservableObject {
    private static let cryTriggeredPlaybackDuration: TimeInterval = 5 * 60
    private static let cryTriggeredSoundID = "white-noise"
    private static let defaultRoutineDuration: TimeInterval = 30 * 60

    @Published var selectedSound: SoundDefinition
    @Published var volume: Float
    @Published var timerRemaining: TimeInterval = 0
    @Published var isPlaying = false
    @Published var warningBanner: String?
    @Published var cryModeEnabled: Bool
    @Published var cryDetectionThreshold: Float
    @Published private(set) var isCryMonitoringActive = false
    @Published private(set) var lastCryDetectionTime: Date?
    @Published private(set) var lastCryConfidence: Float?
    @Published private(set) var lastCryActionSummary = "No cry events yet"
    @Published private(set) var cryCooldownRemaining: TimeInterval = 0
    @Published private(set) var recentCryEvents: [CryEventRow] = []
    @Published private(set) var favoriteSoundIDs: Set<String>
    @Published private(set) var recentSoundIDs: [String]
    @Published private(set) var routinePresets: [RoutinePreset]
    @Published private(set) var defaultRoutinePresetID: UUID?

    let catalog: [SoundDefinition]

    private var settings: AppSettings
    private let audio: AudioPlaybackControlling
    private let timer: SleepTimerScheduling
    private let store: SettingsStoring
    private let cryService: CryDetectionControlling
    private let systemVolume: SystemVolumeControlling
    private let playbackSessionStore: PlaybackSessionStoring
    private let safetyPolicy: NoiseSafetyPolicy
    private let cryResponseCoordinator: CryResponseCoordinator
    private let dateProvider: () -> Date
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
        playbackSessionStore: PlaybackSessionStoring,
        safetyPolicy: NoiseSafetyPolicy,
        cryResponseCoordinator: CryResponseCoordinator,
        dateProvider: @escaping () -> Date = Date.init
    ) {
        self.catalog = catalogService.sounds
        self.audio = audio
        self.timer = timer
        self.store = store
        self.cryService = cryService
        self.systemVolume = systemVolume ?? NoOpSystemVolumeController()
        self.playbackSessionStore = playbackSessionStore
        self.safetyPolicy = safetyPolicy
        self.cryResponseCoordinator = cryResponseCoordinator
        self.dateProvider = dateProvider

        settings = store.load()
        settings.timer.duration = Self.defaultRoutineDuration
        store.save(settings)
        selectedSound = catalogService.sound(id: settings.lastSoundID) ?? catalogService.sounds[0]
        volume = safetyPolicy.clamped(volume: self.systemVolume.currentVolume)
        cryModeEnabled = settings.cryResponse.enabled
        cryDetectionThreshold = settings.cryResponse.detectionThreshold
        favoriteSoundIDs = settings.favoriteSoundIDs
        recentSoundIDs = settings.recentSoundIDs
        recentCryEvents = store.loadCryEvents(limit: 12).map(CryEventRow.init)

        if settings.routinePresets.isEmpty {
            settings.routinePresets = RoutinePreset.seededDefaults(using: settings)
            settings.defaultRoutinePresetID = settings.routinePresets.first?.id
            store.save(settings)
        }

        routinePresets = settings.routinePresets
        defaultRoutinePresetID = settings.defaultRoutinePresetID

        bind()
        cryService.updateDetectionThreshold(settings.cryResponse.detectionThreshold)
        cryService.updateCooldown(settings.cryResponse.cooldown)
        restorePlaybackSessionIfNeeded()
        startCryMonitoringIfNeeded()
        refreshCooldownState()
    }

    deinit {
        playbackTask?.cancel()
        cryMonitoringTask?.cancel()
    }

    func quickStart() {
        startRoutine(sound: selectedSound, volume: volume, timerDuration: settings.timer.duration, cryModeEnabled: cryModeEnabled)
    }

    func startDefaultRoutine() {
        quickStart()
    }

    func startPreset(_ preset: PlaybackPreset) async {
        let config = quickPresetConfiguration(for: preset)
        let presetSound = quickPresetSound(for: preset)
        settings.timer.duration = config.duration
        selectSound(presetSound)
        toggleCryMode(config.cryModeEnabled)
        store.save(settings)
        await startPlayback(
            sound: presetSound,
            duration: settings.timer.duration,
            micModeEnabled: settings.cryResponse.enabled
        )
    }

    func quickPresetConfiguration(for preset: PlaybackPreset) -> QuickStartPresetSettings {
        settings.quickStartPresets[preset.rawValue] ?? .default(for: preset)
    }

    func updateQuickPreset(_ preset: PlaybackPreset, durationMinutes: Int? = nil, cryModeEnabled: Bool? = nil, soundID: String? = nil) {
        var config = quickPresetConfiguration(for: preset)
        if let durationMinutes {
            config.duration = TimeInterval(max(1, durationMinutes) * 60)
        }
        if let cryModeEnabled {
            config.cryModeEnabled = cryModeEnabled
        }
        if let soundID {
            config.soundID = soundID
        }
        settings.quickStartPresets[preset.rawValue] = config
        store.save(settings)
    }


    func quickPresetSound(for preset: PlaybackPreset) -> SoundDefinition {
        let config = quickPresetConfiguration(for: preset)
        if let soundID = config.soundID,
           let sound = catalog.first(where: { $0.id == soundID }) {
            return sound
        }
        return selectedSound
    }

    func clearCryEvents() {
        store.clearCryEvents()
        recentCryEvents = []
        lastCryActionSummary = "No cry events yet"
    }


    var defaultRoutinePreset: RoutinePreset? {
        guard let defaultRoutinePresetID else { return nil }
        return routinePresets.first(where: { $0.id == defaultRoutinePresetID })
    }

    func startRoutine(preset: RoutinePreset) {
        applyPreset(preset)
        startRoutine(sound: selectedSound, volume: volume, timerDuration: settings.timer.duration, cryModeEnabled: cryModeEnabled)
    }

    func saveCurrentAsPreset(named name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let preset = RoutinePreset(
            name: trimmed,
            soundID: selectedSound.id,
            volume: volume,
            timerDuration: settings.timer.duration,
            cryModeEnabled: cryModeEnabled
        )
        settings.routinePresets.append(preset)
        if settings.defaultRoutinePresetID == nil {
            settings.defaultRoutinePresetID = preset.id
        }
        syncRoutineSettings()
    }

    func renamePreset(id: UUID, name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty,
              let index = settings.routinePresets.firstIndex(where: { $0.id == id })
        else { return }
        settings.routinePresets[index].name = trimmed
        syncRoutineSettings()
    }

    func movePresets(from source: IndexSet, to destination: Int) {
        let moving = source.sorted().map { settings.routinePresets[$0] }
        for index in source.sorted(by: >) {
            settings.routinePresets.remove(at: index)
        }
        var insertAt = destination
        for index in source where index < destination {
            insertAt -= 1
        }
        settings.routinePresets.insert(contentsOf: moving, at: max(0, min(insertAt, settings.routinePresets.count)))
        syncRoutineSettings()
    }

    func setDefaultPreset(id: UUID) {
        guard settings.routinePresets.contains(where: { $0.id == id }) else { return }
        settings.defaultRoutinePresetID = id
        syncRoutineSettings()
    }

    func applyPreset(_ preset: RoutinePreset) {
        guard catalog.contains(where: { $0.id == preset.soundID }) else { return }
        if let sound = catalog.first(where: { $0.id == preset.soundID }) {
            selectSound(sound)
        }
        setVolume(preset.volume)
        settings.timer.duration = preset.timerDuration
        toggleCryMode(preset.cryModeEnabled)
        store.save(settings)
    }

    func stopPlayback() {
        Task { await stopPlaybackFromAutomation() }
    }

    func stopPlaybackFromAutomation() async {
        timer.cancel()
        playbackSessionStore.clear()
        await audio.stop(fadeDuration: 0.3)
        isPlaying = false
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
        persistPlaybackSnapshotIfNeeded()
    }

    func selectSound(_ sound: SoundDefinition) {
        selectedSound = sound
        settings.lastSoundID = sound.id
        settings.recentSoundIDs.removeAll(where: { $0 == sound.id })
        settings.recentSoundIDs.insert(sound.id, at: 0)
        settings.recentSoundIDs = Array(settings.recentSoundIDs.prefix(5))
        recentSoundIDs = settings.recentSoundIDs
        store.save(settings)

        guard isPlaying else { return }

        Task { [weak self] in
            guard let self else { return }
            do {
                try self.audio.configureSession(micModeEnabled: self.cryModeEnabled)
                try await self.audio.play(
                    sound: sound,
                    volume: self.safetyPolicy.clamped(volume: self.volume)
                )
                self.persistPlaybackSnapshotIfNeeded()
            } catch {
                self.warningBanner = "Couldn't switch sound: \(error.localizedDescription)"
                homeLogger.error("sound switch failed: \(error.localizedDescription, privacy: .public)")
            }
        }
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

    var cryMonitoringStatusLabel: String {
        if !cryModeEnabled { return "Off" }
        return isCryMonitoringActive ? "On" : "Unavailable"
    }

    var cryCooldownStatusLabel: String {
        guard cryModeEnabled else { return "Monitoring off" }
        if cryCooldownRemaining <= 0 { return "Ready" }
        return "Cooling down (\(Int(cryCooldownRemaining.rounded(.up)))s)"
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
                isCryMonitoringActive = false
                lastCryActionSummary = "Monitoring turned off"
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

    private func syncRoutineSettings() {
        routinePresets = settings.routinePresets
        defaultRoutinePresetID = settings.defaultRoutinePresetID
        store.save(settings)
    }

    private func startRoutine(sound: SoundDefinition, volume: Float, timerDuration: TimeInterval, cryModeEnabled: Bool) {
        Task {
            do {
                try audio.configureSession(micModeEnabled: cryModeEnabled)
                try await audio.play(sound: sound, volume: safetyPolicy.clamped(volume: volume))
                timer.start(duration: timerDuration, fadeDuration: settings.timer.fadeDuration)
                isPlaying = true
            } catch {
                isPlaying = false
                warningBanner = "Playback failed: \(error.localizedDescription)"
                homeLogger.error("quickStart failed: \(error.localizedDescription, privacy: .public)")
            }
        }
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
                    _ = advancePlaybackGeneration()
                    isPlaying = false
                    playbackSessionStore.clear()
                    Task { await self.audio.stop(fadeDuration: 0.3) }
                }

                let fadeGain = FadeCurve.gain(remaining: state.remaining, fadeDuration: state.fadeDuration)
                if state.isRunning {
                    audio.updateVolume(volume * fadeGain, rampDuration: 0.5)
                    persistPlaybackSnapshotIfNeeded()
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

                lastCryDetectionTime = signal.date
                lastCryConfidence = signal.confidence
                var actions: [CryDetectionEvent.Action] = [.increasedVolume]

                setVolume(action.targetVolume)
                if isPlaying {
                    timer.extend(by: action.timerExtension)
                    actions.append(.extendedTimer)
                    lastCryActionSummary = "Increased volume and extended timer"
                } else {
                    startCryTriggeredPlayback()
                    actions.append(.startedPlayback)
                    lastCryActionSummary = "Started playback and increased volume"
                }
                if action.shouldRecordEvent {
                    store.appendCryEvent(.init(timestamp: signal.date, confidence: signal.confidence, actions: actions))
                    recentCryEvents = store.loadCryEvents(limit: 12).map(CryEventRow.init)
                }
                refreshCooldownState()
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

        Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.refreshCooldownState()
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
            isCryMonitoringActive = false
            warningBanner = "Microphone access is off. Enable it in Settings > Privacy & Security > Microphone to use Cry Response Mode."
            store.save(settings)
            return
        }

        do {
            try audio.configureSession(micModeEnabled: true)
            cryService.updateDetectionThreshold(settings.cryResponse.detectionThreshold)
            cryService.updateCooldown(settings.cryResponse.cooldown)
            try cryService.start()
            isCryMonitoringActive = true
            lastCryActionSummary = "Monitoring and waiting for cry patterns"
        } catch {
            cryModeEnabled = false
            settings.cryResponse.enabled = false
            isCryMonitoringActive = false
            warningBanner = "Cry monitoring couldn’t start. Confirm microphone availability and try again. Error: \(error.localizedDescription)"
            store.save(settings)
        }
    }

    private func startCryTriggeredPlayback() {
        let targetSound = catalog.first(where: { $0.id == Self.cryTriggeredSoundID }) ?? selectedSound
        Task {
            await startPlayback(
                sound: targetSound,
                duration: Self.cryTriggeredPlaybackDuration,
                micModeEnabled: true
            )
        }
    }

    private func startPlayback(sound: SoundDefinition, duration: TimeInterval, micModeEnabled: Bool) async {
        do {
            try audio.configureSession(micModeEnabled: micModeEnabled)
            try await audio.play(sound: sound, volume: safetyPolicy.clamped(volume: volume))
            timer.start(duration: duration, fadeDuration: settings.timer.fadeDuration)
            isPlaying = true
            persistPlaybackSnapshotIfNeeded()
        } catch {
            isPlaying = false
            warningBanner = "Playback failed: \(error.localizedDescription)"
            homeLogger.error("playback failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    private func persistPlaybackSnapshotIfNeeded() {
        guard isPlaying, timerRemaining > 0 else { return }

        let snapshot = PlaybackSessionSnapshot(
            soundID: selectedSound.id,
            targetVolume: safetyPolicy.clamped(volume: volume),
            expectedEndDate: Date().addingTimeInterval(timerRemaining),
            micModeEnabled: cryModeEnabled
        )
        playbackSessionStore.save(snapshot)
    }

    private func restorePlaybackSessionIfNeeded() {
        guard let snapshot = playbackSessionStore.load() else { return }
        guard snapshot.isStillActive else {
            playbackSessionStore.clear()
            return
        }
        guard let sound = catalog.first(where: { $0.id == snapshot.soundID }) else {
            playbackSessionStore.clear()
            return
        }

        selectedSound = sound
        volume = safetyPolicy.clamped(volume: snapshot.targetVolume)
        startPlaybackSession(
            sound: sound,
            micModeEnabled: snapshot.micModeEnabled,
            duration: snapshot.remainingDuration,
            failurePrefix: "Couldn't restore previous playback session"
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
                try await audio.play(sound: sound, volume: volume)
                timer.start(duration: duration, fadeDuration: settings.timer.fadeDuration)
                isPlaying = true
                persistPlaybackSnapshotIfNeeded()
            } catch {
                guard !Task.isCancelled, generation == playbackGeneration else { return }
                isPlaying = false
                warningBanner = "\(failurePrefix): \(error.localizedDescription)"
            }
        }
    }

    private func advancePlaybackGeneration() -> Int {
        playbackGeneration += 1
        return playbackGeneration
    }

    private func refreshCooldownState() {
        cryCooldownRemaining = cryResponseCoordinator.cooldownRemaining(
            at: dateProvider(),
            settings: settings.cryResponse
        )
    }
}

extension HomeViewModel {
    struct CryEventRow: Identifiable, Equatable {
        let id: UUID
        let timestamp: Date
        let confidence: Float
        let actionDescription: String

        init(event: CryDetectionEvent) {
            id = event.id
            timestamp = event.timestamp
            confidence = event.confidence
            actionDescription = event.actions.isEmpty
                ? "Action recorded"
                : event.actions.map(\.label).joined(separator: " • ")
        }
    }
}

private extension CryDetectionEvent.Action {
    var label: String {
        switch self {
        case .startedPlayback:
            return "Started playback"
        case .increasedVolume:
            return "Increased volume"
        case .extendedTimer:
            return "Extended timer"
        }
    }
}

@MainActor
private final class NoOpSystemVolumeController: SystemVolumeControlling {
    var volumePublisher: AnyPublisher<Float, Never> { Empty().eraseToAnyPublisher() }
    var currentVolume: Float { 0.35 }
    func setSystemVolume(_ value: Float) {}
}
