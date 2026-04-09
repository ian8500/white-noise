import Combine
import Foundation

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var selectedSound: SoundDefinition
    @Published var volume: Float
    @Published var timerRemaining: TimeInterval = 0
    @Published var isPlaying = false
    @Published var warningBanner: String?
    @Published var cryModeEnabled: Bool
    @Published private(set) var favoriteSoundIDs: Set<String>
    @Published private(set) var recentSoundIDs: [String]

    let catalog: [SoundDefinition]

    private var settings: AppSettings
    private let audio: AudioPlaybackControlling
    private let timer: SleepTimerScheduling
    private let store: SettingsStoring
    private let cryService: CryDetectionControlling
    private let safetyPolicy: NoiseSafetyPolicy
    private let cryResponseCoordinator: CryResponseCoordinator
    private var cancellables = Set<AnyCancellable>()

    init(
        catalogService: SoundCatalogProviding,
        audio: AudioPlaybackControlling,
        timer: SleepTimerScheduling,
        store: SettingsStoring,
        cryService: CryDetectionControlling,
        safetyPolicy: NoiseSafetyPolicy,
        cryResponseCoordinator: CryResponseCoordinator
    ) {
        self.catalog = catalogService.sounds
        self.audio = audio
        self.timer = timer
        self.store = store
        self.cryService = cryService
        self.safetyPolicy = safetyPolicy
        self.cryResponseCoordinator = cryResponseCoordinator

        settings = store.load()
        selectedSound = catalogService.sound(id: settings.lastSoundID) ?? catalogService.sounds[0]
        volume = settings.lastVolume
        cryModeEnabled = settings.cryResponse.enabled
        favoriteSoundIDs = settings.favoriteSoundIDs
        recentSoundIDs = settings.recentSoundIDs

        bind()
    }

    func quickStart() {
        Task {
            do {
                try audio.configureSession(micModeEnabled: cryModeEnabled)
                try await audio.play(sound: selectedSound, volume: safetyPolicy.clamped(volume: volume))
                timer.start(duration: settings.timer.duration, fadeDuration: settings.timer.fadeDuration)
                isPlaying = true
            } catch {
                isPlaying = false
                warningBanner = "Playback failed: \(error.localizedDescription)"
                print("[Home] ❌ quickStart failed: \(error.localizedDescription)")
            }
        }
    }

    func setVolume(_ value: Float) {
        let clamped = safetyPolicy.clamped(volume: value)
        if safetyPolicy.shouldWarn(for: value) {
            warningBanner = "Volume capped for hearing safety guidance."
        }
        volume = clamped
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
    }

    func adjustTimerDuration(minutesDelta: Int) {
        let currentMinutes = Int(settings.timer.duration / 60)
        let updatedMinutes = max(1, currentMinutes + minutesDelta)
        settings.timer.duration = TimeInterval(updatedMinutes * 60)
        store.save(settings)
    }

    var formattedTimerRemaining: String {
        Self.formatAsMinutesAndSeconds(timerRemaining)
    }

    var formattedTimerDuration: String {
        Self.formatAsMinutesAndSeconds(settings.timer.duration)
    }

    func toggleCryMode(_ enabled: Bool) {
        cryModeEnabled = enabled
        settings.cryResponse.enabled = enabled
        store.save(settings)

        Task {
            if enabled {
                let granted = await cryService.requestPermission()
                guard granted else {
                    cryModeEnabled = false
                    settings.cryResponse.enabled = false
                    warningBanner = "Microphone permission is required for cry response mode."
                    return
                }
                try? cryService.start()
            } else {
                cryService.stop()
            }
        }
    }

    private func bind() {
        timer.statePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                guard let self else { return }
                timerRemaining = state.remaining
                if !state.isRunning {
                    isPlaying = false
                    Task { await self.audio.stop(fadeDuration: 0.3) }
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
                timer.extend(by: action.timerExtension)
                if action.shouldRecordEvent {
                    store.appendCryEvent(.init(confidence: signal.confidence))
                }
            }
            .store(in: &cancellables)
    }

    private static func formatAsMinutesAndSeconds(_ seconds: TimeInterval) -> String {
        let totalSeconds = max(0, Int(seconds.rounded()))
        let minutes = totalSeconds / 60
        let remainingSeconds = totalSeconds % 60
        return String(format: "%02d:%02d", minutes, remainingSeconds)
    }
}
