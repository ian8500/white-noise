import SwiftUI

@main
struct DreamNestApp: App {
    @State private var environment = AppEnvironment.shared

    var body: some Scene {
        WindowGroup {
            HomeView(viewModel: environment.homeViewModel)
        }
    }
}
