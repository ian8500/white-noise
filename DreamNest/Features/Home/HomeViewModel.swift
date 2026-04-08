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

        bind()
    }

    func quickStart() {
        Task {
            try? audio.configureSession()
            try? await audio.play(sound: selectedSound, volume: safetyPolicy.clamped(volume: volume))
            timer.start(duration: settings.timer.duration, fadeDuration: settings.timer.fadeDuration)
            isPlaying = true
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
        store.save(settings)
    }

    func applyTimerPreset(minutes: Int) {
        settings.timer.duration = TimeInterval(minutes * 60)
        store.save(settings)
    }

    func updateFadeDuration(seconds: TimeInterval) {
        settings.timer.fadeDuration = max(5, min(180, seconds))
        store.save(settings)
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
}
