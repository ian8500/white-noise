import Foundation

@MainActor
final class AppEnvironment {
    static let shared = AppEnvironment.live()

    let homeViewModel: HomeViewModel

    private init(homeViewModel: HomeViewModel) {
        self.homeViewModel = homeViewModel
    }

    static func live() -> AppEnvironment {
        let catalog = SoundCatalogService()
        let store = UserDefaultsSettingsStore()
        let timer = SleepTimerEngine()
        let sessionStore = UserDefaultsPlaybackSessionStore()
        let settings = store.load()

        let homeViewModel = HomeViewModel(
            catalogService: catalog,
            audio: AudioPlaybackService(),
            timer: timer,
            store: store,
            cryService: LocalCryDetectionService(
                stateMachine: CryDetectionStateMachine(
                    config: .init(
                        confidenceTriggerThreshold: settings.cryResponse.detectionThreshold,
                        cooldown: settings.cryResponse.cooldown
                    )
                )
            ),
            systemVolume: SystemVolumeService(),
            safetyPolicy: NoiseSafetyPolicy(
                maxGainCap: settings.noiseProtection.maxGainCap,
                warningThreshold: settings.noiseProtection.warningThreshold
            ),
            cryResponseCoordinator: CryResponseCoordinator(),
            playbackSessionStore: sessionStore
        )

        return AppEnvironment(homeViewModel: homeViewModel)
    }
}
