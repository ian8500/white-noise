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
        VStack(spacing: 14) {
            PremiumTimerStepper(timeText: viewModel.timerDurationFriendlyLabel) { delta in
                softHaptic(style: .soft)
                viewModel.adjustTimerDuration(minutesDelta: delta)
            }

            HStack(spacing: 10) {
                ForEach(quickPresets, id: \.self) { preset in
                    QuickPresetButton(title: preset == 60 ? "1h" : preset == 120 ? "2h" : "\(preset)m", isActive: selectedTimerMinutes == preset) {
                        viewModel.applyTimerPreset(minutes: preset)
                    }
                }
            }
        }
        .padding(16)
        .background(.ultraThinMaterial.opacity(0.25), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private var presetSection: some View {
        HStack(spacing: 12) {
            ForEach([PlaybackPreset.bedtime, .nap], id: \.self) { preset in
                PremiumPresetCard(
                    preset: preset,
                    config: viewModel.quickPresetConfiguration(for: preset),
                    sound: viewModel.quickPresetSound(for: preset),
                    pinned: isPinned(preset)
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
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Smart Resettle")
                    .font(.headline)
                Spacer()
                Toggle("", isOn: Binding(get: { viewModel.cryModeEnabled }, set: { enabled in
                    if enabled { viewModel.prepareCryModeEnablement() } else { viewModel.toggleCryMode(false) }
                }))
                .labelsHidden()
            }
            Picker("Mode", selection: Binding(get: { viewModel.cryComfortMode }, set: viewModel.setCryComfortMode)) {
                ForEach(CryComfortMode.allCases, id: \.self) { mode in Text(mode.title).tag(mode) }
            }
            .pickerStyle(.segmented)
            Text("Microphone processing stays on-device, and Smart Resettle history stays local on this phone.")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.7))
        }
        .padding(14)
        .background(.ultraThinMaterial.opacity(0.2), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
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
    private var selectedTimerMinutes: Int { Int((viewModel.isPlaying ? viewModel.timerRemaining : viewModel.configuredTimerDuration) / 60) }
    private var isRecentlyTriggered: Bool {
        guard let timestamp = viewModel.lastCryDetectionTime else { return false }
        return Date().timeIntervalSince(timestamp) < 90
    }
    private var statusMessage: String { isRecentlyTriggered ? "Cry detected" : viewModel.smartResettleStatusLabel }
    private func isPinned(_ preset: PlaybackPreset) -> Bool { viewModel.smartResettleSession?.preset == preset || (!viewModel.isPlaying && preset == .bedtime) }

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

private struct PremiumTimerStepper: View {
    let timeText: String
    let onAdjust: (Int) -> Void
    private let left = [-10, -5, -1]
    private let right = [1, 5, 10]

    var body: some View {
        HStack(spacing: 8) {
            ForEach(left, id: \.self) { delta in stepperButton(delta) }
            Text(timeText)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
            ForEach(right, id: \.self) { delta in stepperButton(delta) }
        }
    }

    private func stepperButton(_ delta: Int) -> some View {
        PressRepeatButton(title: delta > 0 ? "+\(delta)" : "\(delta)") { onAdjust(delta) }
    }
}

private struct PressRepeatButton: View {
    let title: String
    let action: () -> Void
    @State private var task: Task<Void, Never>?

    var body: some View {
        Text(title)
            .font(.system(size: 14, weight: .semibold, design: .rounded))
            .padding(.horizontal, 10)
            .padding(.vertical, 9)
            .background(Capsule().fill(Color.white.opacity(0.12)))
            .overlay(Capsule().stroke(Color.white.opacity(0.2), lineWidth: 1))
            .contentShape(Capsule())
            .gesture(DragGesture(minimumDistance: 0)
                .onChanged { _ in if task == nil { start() } }
                .onEnded { _ in stop(fire: true) })
            .onDisappear { task?.cancel() }
    }

    private func start() {
        task = Task {
            var interval = 220_000_000
            try? await Task.sleep(nanoseconds: 320_000_000)
            while !Task.isCancelled {
                await MainActor.run { action() }
                try? await Task.sleep(nanoseconds: UInt64(interval))
                interval = max(80_000_000, Int(Double(interval) * 0.86))
            }
        }
    }

    private func stop(fire: Bool) {
        task?.cancel()
        task = nil
        if fire { action() }
    }
}

private struct PremiumPresetCard: View {
    let preset: PlaybackPreset
    let config: QuickStartPresetSettings
    let sound: SoundDefinition
    let pinned: Bool
    let onTap: () -> Void
    let onLongPress: () -> Void

    var body: some View {
        SoundPressableTile(tapAction: onTap, longPressAction: onLongPress, longPressDuration: 0.45) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Label(preset.title, systemImage: preset == .bedtime ? "moon.stars.fill" : "cloud.sun.fill")
                    Spacer()
                    if pinned { Image(systemName: "pin.fill").foregroundStyle(Color(hex: "E4A890")) }
                }
                .font(.headline)
                Text(sound.title)
                    .font(.subheadline.weight(.semibold))
                Text("\(Int(config.duration/60)) min • Smart \(config.smartResettleEnabled ? "On" : "Off")")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.7))
            }
            .foregroundStyle(.white)
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.ultraThinMaterial.opacity(0.22), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
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
