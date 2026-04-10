import AppIntents

@available(iOS 16.0, *)
struct StartNapIntent: AppIntent {
    static var title: LocalizedStringResource = "Start Nap"
    static var description = IntentDescription("Start DreamNest playback with the nap preset.")

    func perform() async throws -> some IntentResult {
        await AppEnvironment.shared.homeViewModel.startPreset(.nap)
        return .result()
    }
}

@available(iOS 16.0, *)
struct StartBedtimeIntent: AppIntent {
    static var title: LocalizedStringResource = "Start Bedtime"
    static var description = IntentDescription("Start DreamNest playback with the bedtime preset.")

    func perform() async throws -> some IntentResult {
        await AppEnvironment.shared.homeViewModel.startPreset(.bedtime)
        return .result()
    }
}

@available(iOS 16.0, *)
struct StopPlaybackIntent: AppIntent {
    static var title: LocalizedStringResource = "Stop Playback"
    static var description = IntentDescription("Stop DreamNest audio playback.")

    func perform() async throws -> some IntentResult {
        await AppEnvironment.shared.homeViewModel.stopPlaybackFromAutomation()
        return .result()
    }
}

@available(iOS 16.0, *)
struct DreamNestShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        [
            AppShortcut(
                intent: StartNapIntent(),
                phrases: [
                    "Start nap in \(.applicationName)",
                    "Nap mode in \(.applicationName)"
                ],
                shortTitle: "Start Nap",
                systemImageName: "moon.zzz"
            ),
            AppShortcut(
                intent: StartBedtimeIntent(),
                phrases: [
                    "Start bedtime in \(.applicationName)",
                    "Bedtime mode in \(.applicationName)"
                ],
                shortTitle: "Start Bedtime",
                systemImageName: "bed.double.fill"
            ),
            AppShortcut(
                intent: StopPlaybackIntent(),
                phrases: [
                    "Stop playback in \(.applicationName)",
                    "Stop \(.applicationName)"
                ],
                shortTitle: "Stop Playback",
                systemImageName: "stop.fill"
            )
        ]
    }
}
