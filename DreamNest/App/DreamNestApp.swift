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
                    smartResettleCard
                    cryDetectionCard
                    cryAlertCard
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

    private var smartResettleCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Smart Resettle")
                .foregroundStyle(DreamNestTheme.primaryText)
                .font(.headline)

            Text("After a Sleep or Nap session ends, DreamNest can keep listening for a short time and gently restart soothing audio if crying returns.")
                .foregroundStyle(DreamNestTheme.secondaryText)
                .font(.footnote)

            Text("A convenience soothing feature designed to help your little one settle back down.")
                .foregroundStyle(DreamNestTheme.secondaryText.opacity(0.9))
                .font(.caption)
        }
        .padding()
        .background(DreamNestTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var cryAlertCard: some View {
        NavigationLink {
            CryDetectionAlertsView(viewModel: viewModel)
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "waveform.and.magnifyingglass")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(DreamNestTheme.accent)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Smart Resettle History")
                        .font(.headline)
                        .foregroundStyle(DreamNestTheme.primaryText)
                    Text("View cry and resettle events")
                        .font(.footnote)
                        .foregroundStyle(DreamNestTheme.secondaryText)
                }

                Spacer()

                Text("\(viewModel.recentCryEvents.count)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(DreamNestTheme.primaryText)
            }
            .padding()
            .background(DreamNestTheme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

private struct CryDetectionAlertsView: View {
    @ObservedObject var viewModel: HomeViewModel
    @State private var showClearConfirmation = false

    private var alerts: [HomeViewModel.CryEventRow] {
        viewModel.loadCryEventRows(limit: 1000)
    }

    var body: some View {
        ZStack {
            DreamNestTheme.background.ignoresSafeArea()

            if alerts.isEmpty {
                ContentUnavailableView(
                    "No cry alerts yet",
                    systemImage: "bell.slash",
                    description: Text("When DreamNest detects crying, alerts will appear here.")
                )
            } else {
                List {
                    Section {
                        ForEach(alerts) { alert in
                            CryAlertRow(event: alert)
                                .listRowBackground(DreamNestTheme.cardBackground)
                        }
                    }

                    Section {
                        Button(role: .destructive) {
                            showClearConfirmation = true
                        } label: {
                            Text("Clear All Alerts")
                                .frame(maxWidth: .infinity, alignment: .center)
                        }
                    }
                    .listRowBackground(DreamNestTheme.cardBackground)
                }
                .scrollContentBackground(.hidden)
            }
        }
        .navigationTitle("Smart Resettle Alerts")
        .alert("Clear all alerts?", isPresented: $showClearConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Clear All", role: .destructive) {
                viewModel.clearCryEvents()
            }
        } message: {
            Text("This will remove all Smart Resettle and cry alert history.")
        }
    }
}

private struct CryAlertRow: View {
    let event: HomeViewModel.CryEventRow

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(Self.dateFormatter.string(from: event.timestamp))
                .foregroundStyle(DreamNestTheme.primaryText)
                .font(.subheadline.weight(.semibold))

            Text(event.actionDescription)
                .foregroundStyle(DreamNestTheme.secondaryText)
                .font(.footnote)

            Text(event.detailDescription)
                .foregroundStyle(DreamNestTheme.secondaryText.opacity(0.75))
                .font(.caption)

            if event.confidence > 0 {
                Text("Confidence \(Int((event.confidence * 100).rounded()))%")
                    .foregroundStyle(DreamNestTheme.secondaryText.opacity(0.65))
                    .font(.caption2)
            }
        }
        .padding(.vertical, 4)
    }
}
