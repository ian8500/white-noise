import SwiftUI
import Combine
#if os(iOS)
import UIKit
#endif

struct HomeView: View {
    @StateObject var viewModel: HomeViewModel
    @State private var backgroundBreathing = false
    @State private var isShowingSoundPicker = false
    @State private var isShowingHistory = false
    @State private var isShowingHelpNow = false
    @State private var lowStimulationMode = false
    @State private var selectedStateCard: NightState = .cantSleep
    @State private var promptIndex = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let quickPresets = [30, 45, 60, 120]
    private let promptRotation = Timer.publish(every: 7, on: .main, in: .common).autoconnect()

    private enum NightState: String, CaseIterable {
        case cantSleep
        case wiredAfterWork
        case overwhelmed
        case needReset

        var style: NightStateCard.Style {
            switch self {
            case .cantSleep:
                return .init(icon: "moon.stars", title: "Can't sleep", subtitle: "Quiet your system and settle back in.", gradient: [Color(hex: "2A3F6C"), Color(hex: "192947")])
            case .wiredAfterWork:
                return .init(icon: "bolt.horizontal.fill", title: "Wired after work", subtitle: "Ease out of high alert and downshift.", gradient: [Color(hex: "3D3A66"), Color(hex: "242D50")])
            case .overwhelmed:
                return .init(icon: "brain.head.profile", title: "Feeling overwhelmed", subtitle: "Create breathing room in a heavy moment.", gradient: [Color(hex: "3E4869"), Color(hex: "212D44")])
            case .needReset:
                return .init(icon: "arrow.clockwise", title: "Need a reset", subtitle: "One small reset can change the whole night.", gradient: [Color(hex: "2F4867"), Color(hex: "1E3248")])
            }
        }
    }

    private let prompts = [
        "Let tonight be simple: one slow exhale at a time.",
        "You do not need perfect sleep—just a softer landing.",
        "Name one worry and place it outside this room.",
        "Your only job right now is to downshift.",
        "The next 60 seconds can still be restorative."
    ]

    var body: some View {
        ZStack {
            DreamGradientBackground(isBreathing: $backgroundBreathing, lowStimulationMode: lowStimulationMode)
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: lowStimulationMode ? 14 : HomeLayout.sectionSpacing) {
                    heroHeader
                    if !lowStimulationMode { stateQuestionSection }
                    tonightAnchorSection
                    helpNowButton
                    quickResetLibrarySection
                    nightReplaySection
                    if !lowStimulationMode { supportivePromptSection }
                    if !lowStimulationMode { supportingControls }
                    trustSignals
                }
                .frame(maxWidth: .infinity, alignment: .top)
                .safeAreaPadding(.horizontal, lowStimulationMode ? 24 : HomeLayout.horizontalPadding)
                .safeAreaPadding(.top, HomeLayout.topSafeAreaPadding)
                .safeAreaPadding(.bottom, HomeLayout.bottomSafeAreaPadding)
                .padding(.bottom, HomeLayout.footerBottomSpacing)
            }
        }
        .onAppear {
            let animation = Animation.easeInOut(duration: (reduceMotion || lowStimulationMode) ? 8 : 5.6).repeatForever(autoreverses: true)
            withAnimation(animation) { backgroundBreathing.toggle() }
        }
        .sheet(isPresented: $isShowingSoundPicker) { soundPicker }
        .sheet(isPresented: $isShowingHistory) {
            SmartResettleHistoryView(rows: viewModel.recentCryEvents, onClear: viewModel.clearSmartResettleHistory)
        }
        .sheet(isPresented: $isShowingHelpNow) {
            HelpNowModeView {
                lowStimulationMode = true
                viewModel.applyTimerPreset(minutes: 2)
                viewModel.startDefaultRoutine()
            }
        }
    }

    private var heroHeader: some View {
        VStack(alignment: .leading, spacing: 10) {
            HomeSectionHeader(
                eyebrow: "Night Copilot",
                title: "Good evening.",
                subtitle: "A premium calm companion for tired minds and overstimulated nights."
            )

            Toggle(isOn: $lowStimulationMode.animation(.easeInOut(duration: 0.2))) {
                Label("Low-Stimulation Mode", systemImage: "moon.zzz.fill")
                    .font(lowStimulationMode ? .headline.weight(.semibold) : .subheadline.weight(.semibold))
                    .foregroundStyle(DreamNestTheme.primaryText)
            }
            .toggleStyle(.switch)
            .tint(DreamNestTheme.accent)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Color.white.opacity(0.08)))
            .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(Color.white.opacity(0.12), lineWidth: 1))
            .accessibilityHint("Reduces visual complexity, motion, and contrast for gentler viewing")
        }
        .padding(.bottom, HomeLayout.headerBottomSpacing)
    }

    private var stateQuestionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("What kind of night is this?")
                .font(.title3.weight(.semibold))
                .foregroundStyle(.white)

            LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                ForEach(NightState.allCases, id: \.self) { state in
                    NightStateCard(style: state.style, isActive: selectedStateCard == state) {
                        handleStateSelection(state)
                    }
                }
            }
        }
    }

    private var tonightAnchorSection: some View {
        let anchor = viewModel.tonightAnchor

        return VStack(alignment: .leading, spacing: lowStimulationMode ? 10 : 14) {
            HStack {
                Text("Tonight's Anchor")
                    .font(lowStimulationMode ? .title2.weight(.semibold) : .title3.weight(.semibold))
                    .foregroundStyle(.white)
                Spacer()
                Label("Signature", systemImage: "sparkles")
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(Color.white.opacity(0.14)))
                    .foregroundStyle(.white.opacity(0.86))
            }

            Text(anchor.prompt)
                .font(lowStimulationMode ? .title3.weight(.medium) : .title3.weight(.semibold))
                .foregroundStyle(.white)

            Text(anchor.supportingLine)
                .font(lowStimulationMode ? .body : .subheadline)
                .foregroundStyle(.white.opacity(0.78))

            PrimaryActionButton(
                title: anchor.ctaTitle,
                systemImage: viewModel.mainButtonIsActive ? "stop.fill" : "play.fill"
            ) {
                softHaptic(style: .soft)
                anchor.action()
            }

            SessionStatusCard(
                title: primaryStatusTitle,
                detail: secondaryStatusDetail,
                tone: statusTone,
                onOpenRecentEvents: { isShowingHistory = true }
            )
        }
        .padding(lowStimulationMode ? 18 : 20)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: lowStimulationMode
                            ? [Color(hex: "253553").opacity(0.78), Color(hex: "1A243A").opacity(0.82)]
                            : [Color(hex: "394F7C").opacity(0.72), Color(hex: "1A243A").opacity(0.82)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).stroke(Color.white.opacity(0.2), lineWidth: 1.2))
        .shadow(color: DreamNestTheme.accent.opacity(lowStimulationMode ? 0.12 : 0.25), radius: 20, y: 10)
    }

    private var helpNowButton: some View {
        PrimaryActionButton(title: "Help Now", systemImage: "hand.raised.fill", isProminent: true) {
            softHaptic(style: .medium)
            isShowingHelpNow = true
        }
    }

    private var quickResetLibrarySection: some View {
        let resets = QuickResetItem.seeded

        return SupportCard(
            title: "Quick Reset Library",
            subtitle: "Choose a gentle intervention in one tap—designed for foggy, late-night moments."
        ) {
            VStack(spacing: 10) {
                ForEach(resets) { reset in
                    Button {
                        launch(reset: reset)
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: reset.icon)
                                .font(.headline)
                                .frame(width: 34, height: 34)
                                .background(Circle().fill(Color.white.opacity(0.11)))
                            VStack(alignment: .leading, spacing: 2) {
                                Text(reset.title)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.white)
                                Text(reset.subtitle)
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.7))
                            }
                            Spacer()
                            Text(reset.durationLabel)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.white.opacity(0.78))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Color.white.opacity(0.08)))
                    }
                    .buttonStyle(CalmScaleButtonStyle())
                }
            }
        }
    }

    private var nightReplaySection: some View {
        let replay = viewModel.nightReplay

        return SupportCard(
            title: "Night Replay",
            subtitle: "A kind morning reflection, not a scorecard."
        ) {
            VStack(alignment: .leading, spacing: 8) {
                Text(replay.headline)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)

                Text("• Tools used: \(replay.toolsUsed)")
                    .foregroundStyle(.white.opacity(0.8))
                Text("• Most used: \(replay.mostUsed)")
                    .foregroundStyle(.white.opacity(0.8))
                Text("• Settled fastest with: \(replay.fastestSettle)")
                    .foregroundStyle(.white.opacity(0.8))
            }
            .font(lowStimulationMode ? .body : .footnote.weight(.medium))
        }
    }

    private var supportivePromptSection: some View {
        CalmPromptCard(text: prompts[promptIndex])
            .onReceive(promptRotation) { _ in
                withAnimation(.easeInOut(duration: 0.45)) {
                    promptIndex = (promptIndex + 1) % prompts.count
                }
            }
            .transition(.opacity.combined(with: .scale(scale: 0.99)))
    }

    private var supportingControls: some View {
        VStack(spacing: 12) {
            TimerControlCard(
                timeText: viewModel.formattedTimerDuration,
                selectedPresetMinutes: viewModel.selectedTimerPresetMinutes,
                quickPresets: quickPresets,
                onAdjust: viewModel.adjustTimerDuration,
                onSelectPreset: viewModel.applyTimerPreset
            )

            SoundSelectionSummaryView(
                sound: viewModel.selectedSound,
                isPlaying: viewModel.isPlaying,
                tapAction: { isShowingSoundPicker = true },
                longPressAction: { isShowingSoundPicker = true }
            )
        }
    }

    private var trustSignals: some View {
        Text("No accounts. No scrolling loops. No performance pressure—just support when the night feels heavy.")
            .font(lowStimulationMode ? .body.weight(.medium) : .footnote.weight(.medium))
            .foregroundStyle(.white.opacity(lowStimulationMode ? 0.8 : 0.68))
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, HomeLayout.footerHorizontalPadding)
            .padding(.vertical, HomeLayout.footerVerticalPadding)
    }

    private var soundPicker: some View {
        SoundPickerSheet(
            sounds: viewModel.catalog,
            selectedSoundID: viewModel.selectedSound.id,
            title: "Choose Sound",
            applyButtonTitle: "Use Sound",
            onSelect: viewModel.selectSound,
            onApply: {}
        )
        .presentationDetents([.fraction(0.72), .large])
    }

    private func launch(reset: QuickResetItem) {
        softHaptic(style: .light)
        if let minutes = reset.durationMinutes {
            viewModel.applyTimerPreset(minutes: minutes)
            viewModel.startDefaultRoutine()
        }
    }

    private func handleStateSelection(_ state: NightState) {
        selectedStateCard = state
        softHaptic(style: .light)
        switch state {
        case .cantSleep:
            viewModel.applyTimerPreset(minutes: 45)
        case .wiredAfterWork:
            viewModel.applyTimerPreset(minutes: 30)
        case .overwhelmed:
            viewModel.applyTimerPreset(minutes: 10)
        case .needReset:
            viewModel.applyTimerPreset(minutes: 5)
        }
    }

    private var isRecentlyTriggered: Bool {
        guard let timestamp = viewModel.lastCryDetectionTime else { return false }
        return Date().timeIntervalSince(timestamp) < 90
    }

    private var primaryStatusTitle: String {
        if isRecentlyTriggered { return "Comfort event detected" }
        return viewModel.smartResettleStatusLabel
    }

    private var secondaryStatusDetail: String {
        if isRecentlyTriggered { return "Smart Resettle stepped in. You can review details any time." }
        if viewModel.isPlaying {
            return "\(viewModel.timerDurationFriendlyLabel) remaining in this session."
        }
        return "Ready whenever you are."
    }

    private var statusTone: SessionStatusCard.Tone {
        if isRecentlyTriggered { return .attention }
        if viewModel.isPlaying { return .active }
        return .idle
    }

    private func softHaptic(style: UIImpactFeedbackGenerator.FeedbackStyle) {
#if os(iOS)
        UIImpactFeedbackGenerator(style: style).impactOccurred(intensity: 0.8)
#endif
    }
}

private struct HelpNowModeView: View {
    let startGuidedReset: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color(hex: "101A2B").ignoresSafeArea()

            VStack(alignment: .leading, spacing: 20) {
                Text("Help Now")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Text("You're safe. We'll keep this simple: one breath, one shoulder drop, one minute of quiet.")
                    .font(.title3.weight(.medium))
                    .foregroundStyle(.white.opacity(0.86))

                Button {
                    startGuidedReset()
                    dismiss()
                } label: {
                    Text("Begin 60-second reset")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(RoundedRectangle(cornerRadius: 18).fill(DreamNestTheme.accent))
                }
                .buttonStyle(CalmScaleButtonStyle())

                Text("No decisions required after this.")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.64))
            }
            .padding(24)
        }
    }
}

private struct QuickResetItem: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let durationMinutes: Int?
    let durationLabel: String
    let icon: String

    static let seeded: [QuickResetItem] = [
        .init(title: "60-second reset", subtitle: "Tiny downshift to break stress momentum.", durationMinutes: 1, durationLabel: "1 min", icon: "bolt.slash.fill"),
        .init(title: "2-minute settle", subtitle: "Fast settle for noisy minds.", durationMinutes: 2, durationLabel: "2 min", icon: "moon.zzz.fill"),
        .init(title: "5-minute quiet reset", subtitle: "Let your body catch up with your intention.", durationMinutes: 5, durationLabel: "5 min", icon: "leaf.fill"),
        .init(title: "10-minute wind-down", subtitle: "A fuller transition into sleep mode.", durationMinutes: 10, durationLabel: "10 min", icon: "bed.double.fill"),
        .init(title: "Breathing guide", subtitle: "Longer exhale pattern for nervous-system calm.", durationMinutes: 2, durationLabel: "Breath", icon: "wind"),
        .init(title: "Shoulder + jaw unclench", subtitle: "Release hidden tension before trying sleep again.", durationMinutes: 2, durationLabel: "Release", icon: "figure.mind.and.body")
    ]
}

private struct DreamGradientBackground: View {
    @Binding var isBreathing: Bool
    let lowStimulationMode: Bool

    var body: some View {
        ZStack {
            LinearGradient(
                colors: lowStimulationMode
                    ? [Color(hex: "0A1322"), Color(hex: "151D2D"), Color(hex: "1C2636")]
                    : [Color(hex: "0B1C2C"), Color(hex: "2A3258"), Color(hex: "5E5563")],
                startPoint: .top,
                endPoint: .bottom
            )

            RadialGradient(
                colors: [Color(hex: "E4A890").opacity(lowStimulationMode ? 0.12 : (isBreathing ? 0.28 : 0.18)), .clear],
                center: .center,
                startRadius: 20,
                endRadius: lowStimulationMode ? 240 : (isBreathing ? 350 : 280)
            )
            .blur(radius: lowStimulationMode ? 46 : 32)
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
