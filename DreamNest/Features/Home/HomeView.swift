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
    @State private var isShowingPremiumPreview = false
    @State private var premiumPreviewContext: PremiumPreviewContext = .fullResetLibrary
    @State private var copilotContext: CopilotContext?
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
                    planOverviewSection
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
            } onAskCopilot: {
                presentCopilot(entryPoint: .helpNow)
            }
        }
        .sheet(item: $copilotContext) { context in
            AIChatView(viewModel: AIChatViewModel(context: context))
        }
        .sheet(isPresented: $isShowingPremiumPreview) {
            PremiumPreviewSheet(context: premiumPreviewContext)
        }
    }

    private var heroHeader: some View {
        VStack(alignment: .leading, spacing: 10) {
            HomeSectionHeader(
                eyebrow: "Night Copilot",
                title: "Good evening.",
                subtitle: "A calm, trustworthy night companion with optional Premium depth."
            )

            Button {
                if viewModel.isFeatureAvailable(.lowStimulationMode) {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        lowStimulationMode.toggle()
                    }
                } else {
                    presentPremiumPreview(.lowStimulationMode)
                }
            } label: {
                HStack {
                    Label("Low-Stimulation Mode", systemImage: "moon.zzz.fill")
                        .font(lowStimulationMode ? .headline.weight(.semibold) : .subheadline.weight(.semibold))
                        .foregroundStyle(DreamNestTheme.primaryText)
                    Spacer()
                    if viewModel.isFeatureAvailable(.lowStimulationMode) {
                        Image(systemName: lowStimulationMode ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(.white.opacity(0.88))
                    } else {
                        PremiumPillLabel(title: "Premium")
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Color.white.opacity(0.08)))
                .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(Color.white.opacity(0.12), lineWidth: 1))
            }
            .buttonStyle(CalmScaleButtonStyle())
            .accessibilityHint(viewModel.isFeatureAvailable(.lowStimulationMode) ? "Reduces visual complexity, motion, and contrast for gentler viewing" : "Premium feature preview")
        }
        .padding(.bottom, HomeLayout.headerBottomSpacing)
    }

    private var planOverviewSection: some View {
        SupportCard(
            title: "Tonight, your way",
            subtitle: "Core calm tools stay free. Premium adds depth for tougher nights."
        ) {
            VStack(spacing: 10) {
                planRow(
                    title: "Free",
                    description: "Night states, essential resets, limited Copilot support, and a basic Tonight’s Anchor.",
                    icon: "moon.fill"
                )
                planRow(
                    title: "Premium",
                    description: "Full reset library, low-stimulation mode, deeper Copilot, Night Replay, personalized anchors, and calm themes.",
                    icon: "sparkles",
                    isPremium: true
                )
            }
        }
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

            copilotButton(title: "Ask Copilot", systemImage: "sparkles.rectangle.stack", entryPoint: .nightState)
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

            if !viewModel.isFeatureAvailable(.personalizedAnchor) {
                lockedPremiumHint(
                    text: "Personalize this anchor with your preferred tone and length.",
                    context: .personalizedAnchor
                )
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

            copilotButton(title: "Ask Copilot", systemImage: "moon.stars.fill", entryPoint: .tonightAnchor)
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
        let freeResets = Array(resets.prefix(3))
        let premiumResets = Array(resets.dropFirst(3))

        return SupportCard(
            title: "Quick Reset Library",
            subtitle: "Choose a gentle intervention in one tap—designed for foggy, late-night moments."
        ) {
            VStack(spacing: 10) {
                ForEach(freeResets) { reset in
                    resetRow(reset: reset, isLocked: false)
                }

                ForEach(premiumResets) { reset in
                    resetRow(reset: reset, isLocked: !viewModel.isFeatureAvailable(.fullResetLibrary))
                }

                copilotButton(title: "Ask Copilot after reset", systemImage: "arrow.counterclockwise.circle.fill", entryPoint: .resetCompletion)
            }
        }
    }

    private var nightReplaySection: some View {
        let replay = viewModel.nightReplay

        return SupportCard(
            title: "Night Replay",
            subtitle: "A kind morning reflection, not a scorecard."
        ) {
            if viewModel.isFeatureAvailable(.nightReplay) {
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
            } else {
                lockedPremiumHint(
                    text: "Unlock gentle morning summaries that spot patterns without pressure.",
                    context: .nightReplay
                )
            }
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
            isSoundUnlocked: viewModel.isSoundUnlocked,
            onSelect: viewModel.selectSound,
            onLockedSelect: { _ in presentPremiumPreview(.calmThemes) },
            onApply: {}
        )
        .presentationDetents([.fraction(0.72), .large])
    }

    private func launch(reset: QuickResetItem) {
        softHaptic(style: .light)
        guard !reset.isPremium || viewModel.isFeatureAvailable(.fullResetLibrary) else {
            presentPremiumPreview(.fullResetLibrary)
            return
        }
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

    private func presentCopilot(entryPoint: CopilotContext.EntryPoint) {
        if !canUseCopilot(for: entryPoint) {
            presentPremiumPreview(.deepCopilot)
            return
        }
        copilotContext = CopilotContext(
            entryPoint: entryPoint,
            nightState: selectedStateCard.style.title,
            timerMinutes: viewModel.selectedTimerPresetMinutes ?? viewModel.timerDurationMinutes,
            isLowStimulationMode: lowStimulationMode
        )
    }

    private func canUseCopilot(for entryPoint: CopilotContext.EntryPoint) -> Bool {
        if viewModel.isFeatureAvailable(.deepCopilot) {
            return true
        }
        return entryPoint == .helpNow || entryPoint == .tonightAnchor
    }

    private func presentPremiumPreview(_ context: PremiumPreviewContext) {
        premiumPreviewContext = context
        isShowingPremiumPreview = true
    }

    private func planRow(title: String, description: String, icon: String, isPremium: Bool = false) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
                .frame(width: 28, height: 28)
                .background(Circle().fill(Color.white.opacity(0.11)))
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                    if isPremium {
                        PremiumPillLabel(title: "Premium")
                    }
                }
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.76))
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Color.white.opacity(0.06)))
    }

    private func resetRow(reset: QuickResetItem, isLocked: Bool) -> some View {
        Button {
            if isLocked {
                presentPremiumPreview(.fullResetLibrary)
            } else {
                launch(reset: reset)
            }
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
                    Text(isLocked ? "Included in Premium reset library." : reset.subtitle)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.7))
                }
                Spacer()
                if isLocked {
                    Image(systemName: "lock.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.84))
                } else {
                    Text(reset.durationLabel)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.78))
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Color.white.opacity(0.08)))
        }
        .buttonStyle(CalmScaleButtonStyle())
        .opacity(isLocked ? 0.9 : 1)
    }

    private func lockedPremiumHint(text: String, context: PremiumPreviewContext) -> some View {
        Button {
            presentPremiumPreview(context)
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "lock.fill")
                    .font(.caption.weight(.semibold))
                Text(text)
                    .font(.footnote.weight(.medium))
                    .multilineTextAlignment(.leading)
                Spacer(minLength: 0)
                PremiumPillLabel(title: "Premium")
            }
            .foregroundStyle(.white.opacity(0.86))
            .padding(10)
            .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color.white.opacity(0.08)))
            .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(Color.white.opacity(0.14), lineWidth: 1))
        }
        .buttonStyle(CalmScaleButtonStyle())
    }

    private func copilotButton(title: String, systemImage: String, entryPoint: CopilotContext.EntryPoint) -> some View {
        let unlocked = canUseCopilot(for: entryPoint)

        return Button {
            presentCopilot(entryPoint: entryPoint)
        } label: {
            HStack {
                Label(title, systemImage: unlocked ? systemImage : "lock.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                Spacer()
                if !unlocked {
                    PremiumPillLabel(title: "Premium")
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .padding(.horizontal, 12)
            .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Color.white.opacity(0.1)))
            .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(Color.white.opacity(0.16), lineWidth: 1))
        }
        .buttonStyle(CalmScaleButtonStyle())
    }
}

private struct HelpNowModeView: View {
    let startGuidedReset: () -> Void
    let onAskCopilot: () -> Void
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

                Button {
                    onAskCopilot()
                    dismiss()
                } label: {
                    Text("Ask Copilot")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(RoundedRectangle(cornerRadius: 18).fill(Color.white.opacity(0.12)))
                        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.white.opacity(0.15), lineWidth: 1))
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
    let isPremium: Bool

    static let seeded: [QuickResetItem] = [
        .init(title: "60-second reset", subtitle: "Tiny downshift to break stress momentum.", durationMinutes: 1, durationLabel: "1 min", icon: "bolt.slash.fill", isPremium: false),
        .init(title: "2-minute settle", subtitle: "Fast settle for noisy minds.", durationMinutes: 2, durationLabel: "2 min", icon: "moon.zzz.fill", isPremium: false),
        .init(title: "5-minute quiet reset", subtitle: "Let your body catch up with your intention.", durationMinutes: 5, durationLabel: "5 min", icon: "leaf.fill", isPremium: false),
        .init(title: "10-minute wind-down", subtitle: "A fuller transition into sleep mode.", durationMinutes: 10, durationLabel: "10 min", icon: "bed.double.fill", isPremium: true),
        .init(title: "Breathing guide", subtitle: "Longer exhale pattern for nervous-system calm.", durationMinutes: 2, durationLabel: "Breath", icon: "wind", isPremium: true),
        .init(title: "Shoulder + jaw unclench", subtitle: "Release hidden tension before trying sleep again.", durationMinutes: 2, durationLabel: "Release", icon: "figure.mind.and.body", isPremium: true)
    ]
}

private enum PremiumPreviewContext: String {
    case fullResetLibrary
    case lowStimulationMode
    case deepCopilot
    case nightReplay
    case personalizedAnchor
    case calmThemes

    var title: String {
        switch self {
        case .fullResetLibrary: return "Full Reset Library"
        case .lowStimulationMode: return "Low-Stimulation Mode"
        case .deepCopilot: return "Deeper Copilot Support"
        case .nightReplay: return "Night Replay"
        case .personalizedAnchor: return "Personalized Tonight’s Anchor"
        case .calmThemes: return "Premium Calm Themes"
        }
    }

    var description: String {
        switch self {
        case .fullResetLibrary:
            return "Add richer reset tools for high-stress nights while keeping the core free experience intact."
        case .lowStimulationMode:
            return "Reduce motion, contrast, and cognitive load for a gentler late-night interface."
        case .deepCopilot:
            return "Get longer, context-aware guidance when you want more than a quick suggestion."
        case .nightReplay:
            return "See compassionate summaries that reveal patterns and wins without pressure."
        case .personalizedAnchor:
            return "Shape your nightly anchor around your tone, pacing, and preferred routines."
        case .calmThemes:
            return "Unlock additional visual atmospheres designed for deep evening calm."
        }
    }
}

private struct PremiumPillLabel: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(.white.opacity(0.9))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Capsule().fill(Color.white.opacity(0.16)))
    }
}

private struct PremiumPreviewSheet: View {
    let context: PremiumPreviewContext
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 18) {
                Text("Night Copilot Premium")
                    .font(.caption.weight(.semibold))
                    .tracking(1.1)
                    .foregroundStyle(.white.opacity(0.74))
                Text(context.title)
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(.white)
                Text(context.description)
                    .font(.body)
                    .foregroundStyle(.white.opacity(0.82))

                VStack(alignment: .leading, spacing: 8) {
                    Text("Premium includes:")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.88))
                    ForEach([
                        "Full reset library",
                        "Low-stimulation visual mode",
                        "Deep Night Copilot conversations",
                        "Night Replay summaries",
                        "Personalized anchors and calm themes"
                    ], id: \.self) { item in
                        Label(item, systemImage: "checkmark")
                            .font(.footnote.weight(.medium))
                            .foregroundStyle(.white.opacity(0.82))
                    }
                }
                .padding(14)
                .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Color.white.opacity(0.08)))

                Button("Continue with Free") {
                    dismiss()
                }
                .font(.headline.weight(.semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Color.white.opacity(0.12)))
            }
            .padding(20)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(Color(hex: "101A2B").ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
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
