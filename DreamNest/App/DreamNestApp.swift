import SwiftUI

@main
struct DreamNestApp: App {
    @State private var environment = AppEnvironment.live()

    var body: some Scene {
        WindowGroup {
            HomeView(viewModel: environment.homeViewModel)
        }
    }
}
