import Foundation

@MainActor
struct AppEnvironment {
    let homeViewModel: HomeViewModel

    static func live() -> AppEnvironment {
        let catalog = SoundCatalogService()
        let store = UserDefaultsSettingsStore()
        let timer = SleepTimerEngine()
        let settings = store.load()

        return AppEnvironment(
            homeViewModel: HomeViewModel(
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
                cryResponseCoordinator: CryResponseCoordinator()
            )
        )
    }
}
