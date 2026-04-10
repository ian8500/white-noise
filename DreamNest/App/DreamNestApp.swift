import SwiftUI

@main
struct DreamNestApp: App {
    @State private var environment = AppEnvironment.shared

    var body: some Scene {
        WindowGroup {
            TabView {
                HomeView(viewModel: environment.homeViewModel)
                    .tabItem {
                        Label("Home", systemImage: "house.fill")
                    }

                NavigationStack {
                    SettingsView(viewModel: environment.homeViewModel)
                }
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
            }
        }
    }
}

private struct SettingsView: View {
    @ObservedObject var viewModel: HomeViewModel

    var body: some View {
        ZStack {
            DreamNestTheme.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {
                    cryDetectionCard
                }
                .padding()
            }
        }
        .navigationTitle("Settings")
        .preferredColorScheme(.dark)
    }

    private var cryDetectionCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Cry Detection")
                .foregroundStyle(DreamNestTheme.primaryText)
                .font(.headline)

            Text("Sensitivity: \(Int(viewModel.cryDetectionThreshold * 100))%")
                .foregroundStyle(DreamNestTheme.primaryText)

            Slider(value: Binding(
                get: { Double(viewModel.cryDetectionThreshold) },
                set: { viewModel.setCryDetectionThreshold(Float($0)) }
            ), in: 0.4 ... 0.95)

            Text("Lower values trigger more easily. Higher values require stronger confidence.")
                .foregroundStyle(DreamNestTheme.secondaryText)
                .font(.footnote)
        }
        .padding()
        .background(DreamNestTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}
