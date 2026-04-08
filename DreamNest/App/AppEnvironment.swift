import Foundation

@MainActor
struct AppEnvironment {
    let homeViewModel: HomeViewModel

    static func live() -> AppEnvironment {
        let catalog = SoundCatalogService()
        let store = UserDefaultsSettingsStore()
        let timer = SleepTimerEngine()

        return AppEnvironment(
            homeViewModel: HomeViewModel(
                catalogService: catalog,
                audio: AudioPlaybackService(),
                timer: timer,
                store: store,
                cryService: LocalCryDetectionService(
                    stateMachine: CryDetectionStateMachine(config: .init(cooldown: store.load().cryResponse.cooldown))
                ),
                safetyPolicy: NoiseSafetyPolicy(maxGainCap: store.load().maxGainCap)
            )
        )
    }
}
