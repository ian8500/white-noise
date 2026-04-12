import SwiftUI
import Combine
#if os(iOS)
import UIKit
#endif

struct HomeView: View {
    @StateObject var viewModel: HomeViewModel
    @State private var backgroundBreathing = false
    @State private var editingPreset: PlaybackPreset?
    @State private var isShowingSoundPicker = false
    @State private var isShowingHistory = false

    private let quickPresets = [30, 45, 60, 120]
    
    private enum HomeLayout {
        static let horizontalPadding: CGFloat = 20
        static let sectionSpacing: CGFloat = 18
        static let topSafeAreaPadding: CGFloat = 18
        static let bottomSafeAreaPadding: CGFloat = 28
        static let headerBottomSpacing: CGFloat = 4
        static let heroBottomSpacing: CGFloat = 6
        static let footerTopSpacing: CGFloat = 2
    }

    var body: some View {
        ZStack {
            DreamGradientBackground(isBreathing: $backgroundBreathing)
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: HomeLayout.sectionSpacing) {
                    header
                        .padding(.bottom, HomeLayout.headerBottomSpacing)
                    SleepButton(isActive: viewModel.isPlaying, size: 210, action: toggleSleep)
                        .padding(.bottom, HomeLayout.heroBottomSpacing)
                    statusStrip
                    timerPanel
                    presetSection
                    soundSelector
                    cryConfidencePanel
                    trustSignals
                        .padding(.top, HomeLayout.footerTopSpacing)
                }
                .frame(maxWidth: .infinity, alignment: .top)
                .safeAreaPadding(.horizontal, HomeLayout.horizontalPadding)
                .safeAreaPadding(.top, HomeLayout.topSafeAreaPadding)
                .safeAreaPadding(.bottom, HomeLayout.bottomSafeAreaPadding)
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            withAnimation(.easeInOut(duration: 4.5).repeatForever(autoreverses: true)) { backgroundBreathing.toggle() }
        }
        .sheet(item: $editingPreset) { preset in presetEditor(for: preset) }
        .sheet(isPresented: $isShowingSoundPicker) { soundPicker }
        .sheet(isPresented: $isShowingHistory) { SmartResettleHistoryView(rows: viewModel.recentCryEvents, onClear: viewModel.clearSmartResettleHistory) }
        .sheet(isPresented: $viewModel.showCryOnboarding) {
            CryModeOnboardingView(
                selectedMode: viewModel.cryComfortMode,
                onEnable: { mode in viewModel.completeCryOnboarding(enableNow: true, mode: mode) },
                onLater: { viewModel.completeCryOnboarding(enableNow: false, mode: viewModel.cryComfortMode) },
                onTest: viewModel.runSmartResettleTest
            )
        }
    }

    private var header: some View {
        VStack(spacing: 8) {
            Text("DreamNest")
                .font(.system(size: 42, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            Text("Calm, premium sleep routines")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.7))
        }
    }

    private var statusStrip: some View {
        HStack(spacing: 10) {
            StatusPill(text: statusMessage, isTriggered: isRecentlyTriggered)
            Button {
                isShowingHistory = true
            } label: {
                Image(systemName: "clock.arrow.circlepath")
                    .padding(10)
                    .background(Circle().fill(Color.white.opacity(0.12)))
            }
            .buttonStyle(.plain)
        }
    }

    private var timerPanel: some View {
        TimerControlCard(
            timeText: viewModel.timerDurationFriendlyLabel,
            selectedPresetMinutes: viewModel.selectedTimerPresetMinutes,
            quickPresets: quickPresets
        ) { delta in
            softHaptic(style: .soft)
            withAnimation(.spring(duration: 0.25, bounce: 0.24)) {
                viewModel.adjustTimerDuration(minutesDelta: delta)
            }
        } onSelectPreset: { preset in
            softHaptic(style: .light)
            withAnimation(.spring(duration: 0.3, bounce: 0.2)) {
                viewModel.applyTimerPreset(minutes: preset)
            }
        }
    }

    private var presetSection: some View {
        HStack(spacing: 12) {
            ForEach([PlaybackPreset.bedtime, .nap], id: \.self) { preset in
                let config = viewModel.quickPresetConfiguration(for: preset)
                let sound = viewModel.quickPresetSound(for: preset)
                PresetCard(
                    title: preset.title,
                    icon: presetIcon(for: preset),
                    soundTitle: sound.title,
                    metadata: "\(Int(config.duration / 60)) min • Smart \(config.smartResettleEnabled ? "On" : "Off")",
                    state: cardState(for: preset)
                ) {
                    Task { await viewModel.startPreset(preset) }
                } onLongPress: {
                    editingPreset = preset
                }
            }
        }
    }

    private var soundSelector: some View {
        SoundSelectionSummaryView(sound: viewModel.selectedSound, isPlaying: viewModel.isPlaying) {
            if !viewModel.isPlaying { viewModel.startDefaultRoutine() }
        } longPressAction: {
            isShowingSoundPicker = true
        }
    }

    private var cryConfidencePanel: some View {
        SmartResettleCard(
            isEnabled: Binding(get: { viewModel.cryModeEnabled }, set: { enabled in
                if enabled { viewModel.prepareCryModeEnablement() } else { viewModel.toggleCryMode(false) }
            }),
            mode: Binding(get: { viewModel.cryComfortMode }, set: viewModel.setCryComfortMode),
            onToggleChanged: { enabled in
                if enabled { viewModel.prepareCryModeEnablement() } else { viewModel.toggleCryMode(false) }
            }
        )
    }

    private var trustSignals: some View {
        Text("Designed for safe, restful sleep")
            .font(.footnote)
            .foregroundStyle(.white.opacity(0.72))
    }

    private func presetEditor(for preset: PlaybackPreset) -> some View {
        let config = viewModel.quickPresetConfiguration(for: preset)
        return PresetConfigurationSheet(
            preset: preset,
            selectedSoundID: viewModel.quickPresetSound(for: preset).id,
            durationMinutes: Int(config.duration / 60),
            cryDetectionEnabled: config.cryModeEnabled,
            smartResettleEnabled: config.smartResettleEnabled,
            listeningWindowMinutes: Int(config.listeningWindow / 60),
            resettleDurationMinutes: Int(config.resettleDuration / 60),
            maxAutoResettles: config.maxAutoResettles,
            sounds: soundCatalog,
            onSave: { soundID, minutes, cryEnabled, smartEnabled, listeningMinutes, resettleMinutes, maxCount in
                viewModel.updateQuickPreset(preset, durationMinutes: minutes, cryModeEnabled: cryEnabled, soundID: soundID, smartResettleEnabled: smartEnabled, listeningWindowMinutes: listeningMinutes, resettleDurationMinutes: resettleMinutes, maxAutoResettles: maxCount)
            }
        )
    }

    private var soundPicker: some View {
        SoundPickerSheet(sounds: soundCatalog, selectedSoundID: viewModel.selectedSound.id, title: "Choose Sound", applyButtonTitle: "Use Sound", onSelect: viewModel.selectSound, onApply: {})
            .presentationDetents([.fraction(0.72), .large])
    }

    private var soundCatalog: [SoundDefinition] { viewModel.catalog }
    private var isRecentlyTriggered: Bool {
        guard let timestamp = viewModel.lastCryDetectionTime else { return false }
        return Date().timeIntervalSince(timestamp) < 90
    }
    private var statusMessage: String { isRecentlyTriggered ? "Cry detected" : viewModel.smartResettleStatusLabel }
    private func presetIcon(for preset: PlaybackPreset) -> String {
        switch preset {
        case .bedtime: return "moon.stars.fill"
        case .nap: return "sun.max.fill"
        }
    }

    private func cardState(for preset: PlaybackPreset) -> PresetCard.State {
        var state: PresetCard.State = []
        if viewModel.selectedSound.id == viewModel.quickPresetSound(for: preset).id {
            state.insert(.selected)
        }
        if viewModel.activeQuickPreset == preset && viewModel.isPlaying {
            state.insert(.active)
        }
        if viewModel.smartResettleSession?.preset == preset || (!viewModel.isPlaying && preset == .bedtime) {
            state.insert(.pinned)
        }
        return state
    }

    private func toggleSleep() {
        withAnimation(.easeInOut(duration: 0.3)) {
            viewModel.isPlaying ? viewModel.stopPlayback() : viewModel.startDefaultRoutine()
        }
    }

    private func softHaptic(style: UIImpactFeedbackGenerator.FeedbackStyle) {
#if os(iOS)
        UIImpactFeedbackGenerator(style: style).impactOccurred(intensity: 0.85)
#endif
    }
}

private struct TimerControlCard: View {
    let timeText: String
    let selectedPresetMinutes: Int?
    let quickPresets: [Int]
    let onAdjust: (Int) -> Void
    let onSelectPreset: (Int) -> Void
    private let adjustments = [-10, -5, -1, 1, 5, 10]
    private let columns = [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)]

    var body: some View {
        VStack(spacing: 14) {
            adjustmentSection
            timerDisplay
            presetSection
        }
        .padding(16)
        .background(.ultraThinMaterial.opacity(0.25), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private var adjustmentSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Adjustments")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white.opacity(0.68))
            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(adjustments, id: \.self) { delta in
                    TimerPillButton(title: delta > 0 ? "+\(delta)" : "\(delta)") {
                        onAdjust(delta)
                    }
                    .accessibilityLabel(delta > 0 ? "Increase timer by \(delta) minutes" : "Decrease timer by \(abs(delta)) minutes")
                }
            }
        }
    }

    private var timerDisplay: some View {
        VStack(spacing: 6) {
            Text("Sleep Timer")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white.opacity(0.68))
            Text(timeText)
                .font(.system(size: 40, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .contentTransition(.numericText())
                .animation(.spring(duration: 0.25, bounce: 0.18), value: timeText)
                .accessibilityLabel("Timer duration")
                .accessibilityValue(timeText)
        }
        .padding(.vertical, 8)
    }

    private var presetSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Presets")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white.opacity(0.68))
            HStack(spacing: 10) {
                ForEach(quickPresets, id: \.self) { preset in
                    TimerPillButton(
                        title: presetTitle(for: preset),
                        isSelected: selectedPresetMinutes == preset
                    ) {
                        onSelectPreset(preset)
                    }
                    .accessibilityLabel("Set timer to \(presetTitle(for: preset))")
                    .accessibilityValue(selectedPresetMinutes == preset ? "Selected" : "Not selected")
                }
            }
        }
    }

    private func presetTitle(for minutes: Int) -> String {
        switch minutes {
        case 60: return "1h"
        case 120: return "2h"
        default: return "\(minutes)m"
        }
    }
}

private struct TimerPillButton: View {
    let title: String
    var isSelected = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.92)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .foregroundStyle(.white)
                .background(
                    Capsule()
                        .fill(isSelected ? Color.white.opacity(0.28) : Color.white.opacity(0.12))
                )
                .overlay(
                    Capsule()
                        .stroke(isSelected ? Color.white.opacity(0.85) : Color.white.opacity(0.2), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .frame(minHeight: 44)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }
}

private struct SmartResettleHistoryView: View {
    let rows: [HomeViewModel.CryEventRow]
    let onClear: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                ForEach(rows) { row in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(row.actionDescription).font(.headline)
                        Text(row.detailDescription).font(.subheadline).foregroundStyle(.secondary)
                        Text(row.timestamp, style: .time).font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Smart Resettle History")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { Button("Close") { dismiss() } }
                ToolbarItem(placement: .topBarTrailing) { Button("Clear All", role: .destructive, action: onClear) }
            }
        }
    }
}

private struct CryModeOnboardingView: View {
    @State var selectedMode: CryComfortMode
    let onEnable: (CryComfortMode) -> Void
    let onLater: () -> Void
    let onTest: () -> Void

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                Text("Smart Resettle uses your microphone only to detect cry patterns on-device.")
                Picker("Response Style", selection: $selectedMode) {
                    ForEach(CryComfortMode.allCases, id: \.self) { Text($0.title).tag($0) }
                }
                .pickerStyle(.segmented)
                Button("Test Smart Resettle", action: onTest)
                Button("Enable Cry Features") { onEnable(selectedMode) }
                    .buttonStyle(.borderedProminent)
                Button("Maybe Later", action: onLater)
            }
            .padding(20)
            .navigationTitle("Before You Enable")
        }
    }
}

private struct DreamGradientBackground: View {
    @Binding var isBreathing: Bool
    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(hex: "0B1C2C"), Color(hex: "2E335D"), Color(hex: "6E5E64")], startPoint: .top, endPoint: .bottom)
            RadialGradient(colors: [Color(hex: "E4A890").opacity(isBreathing ? 0.38 : 0.24), .clear], center: .center, startRadius: 18, endRadius: isBreathing ? 360 : 280).blur(radius: 30)
        }
    }
}

private struct SleepButton: View {
    let isActive: Bool
    let size: CGFloat
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: isActive ? "moon.zzz.fill" : "moon.stars.fill")
                Text(isActive ? "Sleeping..." : "Start Sleep")
            }
            .font(.system(.title3, design: .rounded).weight(.semibold))
            .foregroundStyle(.white)
            .frame(width: size, height: size)
            .background(Circle().fill(LinearGradient(colors: [Color(hex: "2A3E62"), Color(hex: "141F36")], startPoint: .topLeading, endPoint: .bottomTrailing)))
            .shadow(color: Color(hex: "E4A890").opacity(0.36), radius: 18, y: 6)
        }
        .buttonStyle(.plain)
    }
}

private struct QuickPresetButton: View {
    let title: String
    let isActive: Bool
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(title).font(.caption.weight(.semibold)).padding(.horizontal, 12).padding(.vertical, 8)
                .background(Capsule().fill(Color.white.opacity(isActive ? 0.24 : 0.1)))
        }.buttonStyle(.plain)
    }
}

private struct SoundSelectionSummaryView: View {
    let sound: SoundDefinition
    let isPlaying: Bool
    let tapAction: () -> Void
    let longPressAction: () -> Void

    var body: some View {
        SoundPressableTile(tapAction: tapAction, longPressAction: longPressAction) {
            HStack {
                let style = SoundVisualStyle.forSound(sound)
                Image(systemName: style.icon).padding(10).background(RoundedRectangle(cornerRadius: 12).fill(style.primary.opacity(0.24)))
                VStack(alignment: .leading) {
                    Text(style.title).font(.headline)
                    Text(style.subtitle).font(.caption).foregroundStyle(.white.opacity(0.7))
                }
                Spacer()
                Image(systemName: "chevron.right")
            }
            .foregroundStyle(.white)
            .padding(14)
            .background(.ultraThinMaterial.opacity(0.24), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
    }
}

private struct SoundPickerSheet: View {
    let sounds: [SoundDefinition]
    let selectedSoundID: String
    let title: String
    let applyButtonTitle: String
    let onSelect: (SoundDefinition) -> Void
    let onApply: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(sounds, id: \.id) { sound in
                        SoundTileView(sound: sound, isSelected: selectedSoundID == sound.id) { onSelect(sound) }
                    }
                }
                .padding()
            }
            .navigationTitle(title)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { Button("Close") { dismiss() } }
                ToolbarItem(placement: .topBarTrailing) { Button(applyButtonTitle) { onApply(); dismiss() } }
            }
        }
    }
}

private struct SoundTileView: View {
    let sound: SoundDefinition
    let isSelected: Bool
    let action: () -> Void
    var body: some View {
        let style = SoundVisualStyle.forSound(sound)
        return Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                Image(systemName: style.icon).font(.title2)
                Text(style.title).font(.headline)
                Text(style.subtitle).font(.caption)
            }
            .foregroundStyle(.white)
            .padding(12)
            .frame(maxWidth: .infinity, minHeight: 120, alignment: .leading)
            .background(style.background.opacity(0.5), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(isSelected ? style.primary : .white.opacity(0.14), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}

private struct PresetConfigurationSheet: View {
    let preset: PlaybackPreset
    @State var selectedSoundID: String
    @State var durationMinutes: Int
    @State var cryDetectionEnabled: Bool
    @State var smartResettleEnabled: Bool
    @State var listeningWindowMinutes: Int
    @State var resettleDurationMinutes: Int
    @State var maxAutoResettles: Int
    let sounds: [SoundDefinition]
    let onSave: (String, Int, Bool, Bool, Int, Int, Int) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Picker("Sound", selection: $selectedSoundID) {
                    ForEach(sounds, id: \.id) { Text($0.title).tag($0.id) }
                }
                Stepper("Duration: \(durationMinutes) min", value: $durationMinutes, in: 1...180)
                Toggle("Cry Detection", isOn: $cryDetectionEnabled)
                Toggle("Smart Resettle", isOn: $smartResettleEnabled)
                if smartResettleEnabled {
                    Stepper("Listening Window: \(listeningWindowMinutes) min", value: $listeningWindowMinutes, in: 15...60, step: 15)
                    Stepper("Resettle Duration: \(resettleDurationMinutes) min", value: $resettleDurationMinutes, in: 3...15)
                    Stepper("Max Auto-Resettles: \(maxAutoResettles)", value: $maxAutoResettles, in: 1...3)
                }
            }
            .navigationTitle("\(preset.title) Preset")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        onSave(selectedSoundID, durationMinutes, cryDetectionEnabled, smartResettleEnabled, listeningWindowMinutes, resettleDurationMinutes, maxAutoResettles)
                        dismiss()
                    }
                }
            }
        }
    }
}

private struct SoundPressableTile<Content: View>: View {
    let tapAction: () -> Void
    let longPressAction: () -> Void
    var longPressDuration: Double = 0.5
    @ViewBuilder let content: () -> Content
    var body: some View {
        content().onTapGesture(perform: tapAction).onLongPressGesture(minimumDuration: longPressDuration, perform: longPressAction)
    }
}

private struct SoundVisualStyle {
    let icon: String
    let title: String
    let subtitle: String
    let primary: Color
    let background: Color
    static func forSound(_ sound: SoundDefinition) -> SoundVisualStyle {
        let id = sound.id.lowercased()
        if id.contains("rain") { return .init(icon: "cloud.rain.fill", title: "Rain", subtitle: "Soft rainfall", primary: Color(hex: "9AB4D8"), background: Color(hex: "354A62")) }
        if id.contains("white") { return .init(icon: "waveform.path", title: "White Noise", subtitle: "Airy masking hush", primary: Color(hex: "D4DFEA"), background: Color(hex: "4A5363")) }
        if id.contains("pink") { return .init(icon: "circle.hexagongrid.fill", title: sound.title, subtitle: "Warm blanket noise", primary: Color(hex: "E0B7C0"), background: Color(hex: "5A3F53")) }
        if id.contains("fire") { return .init(icon: "flame.fill", title: "Fire", subtitle: "Cozy ember crackle", primary: Color(hex: "E4A890"), background: Color(hex: "5B4138")) }
        return .init(icon: "sparkles", title: sound.title, subtitle: "Calm ambience", primary: Color(hex: "B4BDD3"), background: Color(hex: "39435A"))
    }
}

private struct StatusPill: View {
    let text: String
    let isTriggered: Bool
    var body: some View {
        Text(text).font(.footnote.weight(.medium)).foregroundStyle(.white).padding(.horizontal, 14).padding(.vertical, 10)
            .background(Capsule().fill((isTriggered ? Color(hex: "E4A890") : Color(hex: "9BC4FF")).opacity(0.2)))
    }
}

private extension Color {
    init(hex: String) {
        let cleaned = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&int)
        let r, g, b: UInt64
        switch cleaned.count {
        case 6: (r, g, b) = (int >> 16, int >> 8 & 0xFF, int & 0xFF)
        default: (r, g, b) = (245, 247, 250)
        }
        self.init(.sRGB, red: Double(r)/255, green: Double(g)/255, blue: Double(b)/255, opacity: 1)
    }
}

#Preview {
    HomeView(viewModel: .init(
        catalogService: SoundCatalogService(),
        audio: PreviewAudioService(),
        timer: SleepTimerEngine(),
        store: PreviewSettingsStore(),
        cryService: PreviewCryService(),
        playbackSessionStore: UserDefaultsPlaybackSessionStore(defaults: .standard),
        safetyPolicy: .init(),
        cryResponseCoordinator: CryResponseCoordinator()
    ))
}

private final class PreviewAudioService: AudioPlaybackControlling {
    var playbackStatePublisher: AnyPublisher<AudioPlaybackState, Never> { Just(.idle).eraseToAnyPublisher() }
    func configureSession(micModeEnabled: Bool) throws {}
    func play(sound: SoundDefinition, volume: Float) async throws {}
    func pause() {}
    func resume() {}
    func updateVolume(_ volume: Float, rampDuration: TimeInterval) {}
    func stop(fadeDuration: TimeInterval) async {}
}

private final class PreviewCryService: CryDetectionControlling {
    var detectionPublisher: AnyPublisher<CryDetectionSignal, Never> { Empty().eraseToAnyPublisher() }
    func requestPermission() async -> Bool { true }
    func start() throws {}
    func stop() {}
    func updateDetectionThreshold(_ threshold: Float) {}
    func updateCooldown(_ cooldown: TimeInterval) {}
}

private final class PreviewSettingsStore: SettingsStoring {
    private var settings = PreviewData.sampleSettings
    func load() -> AppSettings { settings }
    func save(_ settings: AppSettings) { self.settings = settings }
    func appendCryEvent(_ event: CryDetectionEvent) {}
    func loadCryEvents(limit: Int) -> [CryDetectionEvent] { Array(PreviewData.sampleCryEvents.suffix(limit)) }
    func clearCryEvents() {}
}
