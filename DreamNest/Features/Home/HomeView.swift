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

    private let controlSize: CGFloat = 220
    private let timerAdjustments = [-10, -5, -1, 1, 5, 10]

    var body: some View {
        ZStack {
            DreamGradientBackground(isBreathing: $backgroundBreathing)
                .ignoresSafeArea()

            VStack(spacing: 22) {
                header

                Spacer(minLength: 6)

                SleepButton(
                    isActive: viewModel.isPlaying,
                    size: controlSize,
                    action: toggleSleep
                )
                .transition(.opacity.combined(with: .scale(scale: 0.96)))

                timerPanel

                presetSection

                soundSelector

                StatusPill(
                    text: statusMessage,
                    isTriggered: isRecentlyTriggered
                )
                .transition(.opacity)

                Spacer()

                trustSignals
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 30)
            .safeAreaInset(edge: .top, spacing: 0) {
                Color.clear
                    .frame(height: 10)
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                Color.clear
                    .frame(height: 8)
            }
            .animation(.easeInOut(duration: 0.35), value: viewModel.isPlaying)
            .animation(.easeInOut(duration: 0.35), value: viewModel.selectedSound.id)
            .animation(.easeInOut(duration: 0.35), value: isRecentlyTriggered)
        }
        .preferredColorScheme(.dark)
        .onAppear {
            withAnimation(.easeInOut(duration: 4.5).repeatForever(autoreverses: true)) {
                backgroundBreathing.toggle()
            }
        }
        .sheet(item: $editingPreset) { preset in
            let config = viewModel.quickPresetConfiguration(for: preset)
            PresetConfigurationSheet(
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
                    viewModel.updateQuickPreset(
                        preset,
                        durationMinutes: minutes,
                        cryModeEnabled: cryEnabled,
                        soundID: soundID,
                        smartResettleEnabled: smartEnabled,
                        listeningWindowMinutes: listeningMinutes,
                        resettleDurationMinutes: resettleMinutes,
                        maxAutoResettles: maxCount
                    )
                }
            )
        }
        .sheet(isPresented: $isShowingSoundPicker) {
            SoundPickerSheet(
                sounds: soundCatalog,
                selectedSoundID: viewModel.selectedSound.id,
                title: "Choose Sound",
                applyButtonTitle: "Use Sound",
                onSelect: { sound in
                    withAnimation(.spring(response: 0.34, dampingFraction: 0.84)) {
                        viewModel.selectSound(sound)
                    }
                },
                onApply: {
                    if !viewModel.isPlaying {
                        viewModel.startDefaultRoutine()
                    }
                    softHaptic(style: .soft, intensity: 0.9)
                }
            )
            .presentationDetents([.fraction(0.72), .large])
            .presentationDragIndicator(.visible)
        }
        .alert("Safety Guidance", isPresented: .constant(viewModel.warningBanner != nil), actions: {
            Button("OK") { viewModel.warningBanner = nil }
        }, message: {
            Text(viewModel.warningBanner ?? "")
        })
    }

    private var header: some View {
        VStack(spacing: 10) {
            Text("DreamNest")
                .font(.system(size: 42, weight: .bold, design: .rounded))
                .tracking(0.8)
                .foregroundStyle(Color(red: 0.96, green: 0.97, blue: 0.99))

            Text("Helping your baby sleep, so you can too")
                .font(.system(size: 17, weight: .regular, design: .rounded))
                .foregroundStyle(Color(red: 0.96, green: 0.97, blue: 0.99).opacity(0.72))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("DreamNest. Helping your baby sleep, so you can too")
    }

    private var timerPanel: some View {
        VStack(spacing: 10) {
            Text(viewModel.timerCountdownTitle)
                .font(.system(size: 24, weight: .semibold, design: .rounded))
                .foregroundStyle(Color(hex: "F5F7FA"))

            Text(viewModel.timerCountdownSubtitle)
                .font(.footnote)
                .foregroundStyle(Color(hex: "F5F7FA").opacity(0.7))
                .multilineTextAlignment(.center)
                .lineLimit(2)

            HStack(spacing: 8) {
                ForEach(timerAdjustments, id: \.self) { delta in
                    TimerAdjustmentPill(deltaMinutes: delta) {
                        softHaptic(style: .soft)
                        viewModel.adjustTimerDuration(minutesDelta: delta)
                    }
                }
            }
            .padding(.top, 6)
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 12)
        .background(.ultraThinMaterial.opacity(0.22))
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(hex: "F5F7FA").opacity(0.06))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color(hex: "F5F7FA").opacity(0.15), lineWidth: 1)
        )
    }

    private var presetSection: some View {
        HStack(spacing: 12) {
            ForEach([PlaybackPreset.bedtime, PlaybackPreset.nap], id: \.self) { preset in
                PresetCardView(
                    title: preset == .bedtime ? "Sleep" : "Nap",
                    subtitle: "\(Int(viewModel.quickPresetConfiguration(for: preset).duration / 60)) min • \(viewModel.quickPresetConfiguration(for: preset).smartResettleEnabled ? "Smart On" : "Smart Off")",
                    icon: preset == .bedtime ? "moon.stars.fill" : "cloud.sun.fill",
                    tapAction: {
                        softHaptic(style: .soft)
                        Task { await viewModel.startPreset(preset) }
                    },
                    longPressAction: {
                        softHaptic(style: .rigid, intensity: 0.75)
                        editingPreset = preset
                    }
                )
            }
        }
    }

    private var soundSelector: some View {
        SoundSelectionSummaryView(
            sound: viewModel.selectedSound,
            isPlaying: viewModel.isPlaying,
            tapAction: {
                softHaptic(style: .soft)
                if !viewModel.isPlaying {
                    viewModel.startDefaultRoutine()
                } else {
                    viewModel.selectSound(viewModel.selectedSound)
                }
            },
            longPressAction: {
                softHaptic(style: .rigid, intensity: 0.75)
                isShowingSoundPicker = true
            }
        )
    }

    private var trustSignals: some View {
        VStack(spacing: 6) {
            Text("Designed for safe, restful sleep")
                .font(.footnote.weight(.medium))
                .foregroundStyle(Color(red: 0.96, green: 0.97, blue: 0.99).opacity(0.7))

            Text("Recommended by parents")
                .font(.footnote)
                .foregroundStyle(Color(red: 0.96, green: 0.97, blue: 0.99).opacity(0.48))
        }
        .multilineTextAlignment(.center)
    }

    private var soundCatalog: [SoundDefinition] {
        let preferredOrder = ["rain", "white-noise", "heartbeat", "brown-noise", "waves", "lullaby"]
        let byID = Dictionary(uniqueKeysWithValues: viewModel.catalog.map { ($0.id.lowercased(), $0) })

        let prioritized = preferredOrder.compactMap { byID[$0] }
        let remainders = viewModel.catalog.filter { sound in
            !prioritized.contains(where: { $0.id == sound.id })
        }
        return prioritized + remainders
    }

    private var isRecentlyTriggered: Bool {
        guard let timestamp = viewModel.lastCryDetectionTime else { return false }
        return Date().timeIntervalSince(timestamp) < 90
    }

    private var statusMessage: String {
        if isRecentlyTriggered {
            return "Baby stirred — soothing started 🤍"
        }
        return viewModel.smartResettleStatusLabel
    }

    private func toggleSleep() {
        softHaptic(style: .soft)
        withAnimation(.easeInOut(duration: 0.35)) {
            if viewModel.isPlaying {
                viewModel.stopPlayback()
            } else {
                viewModel.startDefaultRoutine()
            }
        }
    }

    private func softHaptic(style: UIImpactFeedbackGenerator.FeedbackStyle, intensity: CGFloat = 0.85) {
#if os(iOS)
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred(intensity: intensity)
#endif
    }
}

private struct DreamGradientBackground: View {
    @Binding var isBreathing: Bool

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(hex: "0B1C2C"),
                    Color(hex: "2E335D"),
                    Color(hex: "6E5E64")
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            RadialGradient(
                colors: [
                    Color(hex: "E4A890").opacity(isBreathing ? 0.38 : 0.24),
                    Color(hex: "E4A890").opacity(0)
                ],
                center: .center,
                startRadius: 18,
                endRadius: isBreathing ? 360 : 280
            )
            .blur(radius: 30)
            .animation(.easeInOut(duration: 4.5).repeatForever(autoreverses: true), value: isBreathing)
        }
    }
}

private struct SleepButton: View {
    let isActive: Bool
    let size: CGFloat
    let action: () -> Void

    @State private var pulse = false

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color(hex: "E4A890").opacity(isActive ? 0.34 : 0.22), .clear],
                        center: .center,
                        startRadius: 20,
                        endRadius: size * 0.9
                    )
                )
                .frame(width: size * 1.35, height: size * 1.35)
                .scaleEffect(isActive && pulse ? 1.06 : 0.96)
                .opacity(isActive ? 1 : 0.9)
                .blur(radius: 5)

            Button(action: action) {
                VStack(spacing: 11) {
                    Image(systemName: isActive ? "moon.zzz.fill" : "moon.stars.fill")
                        .font(.system(size: 34, weight: .semibold, design: .rounded))

                    Text(isActive ? "Sleeping..." : "Start Sleep")
                        .font(.system(size: 23, weight: .semibold, design: .rounded))
                }
                .foregroundStyle(Color(hex: "F5F7FA"))
                .frame(width: size, height: size)
                .background(
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(hex: "2A3E62").opacity(0.98),
                                    Color(hex: "141F36").opacity(0.98)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
                .overlay(
                    Circle()
                        .stroke(Color(hex: "F5F7FA").opacity(0.26), lineWidth: 1)
                )
                .shadow(color: Color(hex: "E4A890").opacity(isActive ? 0.45 : 0.24), radius: isActive ? 24 : 14, y: 6)
            }
            .buttonStyle(.plain)
            .contentShape(Circle())
            .accessibilityLabel(isActive ? "Sleeping" : "Start Sleep")
            .accessibilityHint("Starts or stops the sleep routine")
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2.8).repeatForever(autoreverses: true)) {
                pulse.toggle()
            }
        }
        .animation(.easeInOut(duration: 0.35), value: isActive)
    }
}

private struct TimerAdjustmentPill: View {
    let deltaMinutes: Int
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(deltaMinutes > 0 ? "+\(deltaMinutes)" : "\(deltaMinutes)")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(Color(hex: "F5F7FA").opacity(0.95))
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity)
                .background(
                    Capsule(style: .continuous)
                        .fill(Color(hex: "F5F7FA").opacity(0.1))
                )
                .overlay(
                    Capsule(style: .continuous)
                        .stroke(Color(hex: "F5F7FA").opacity(0.17), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

private struct SoundSelectionSummaryView: View {
    let sound: SoundDefinition
    let isPlaying: Bool
    let tapAction: () -> Void
    let longPressAction: () -> Void

    var body: some View {
        SoundPressableTile(tapAction: tapAction, longPressAction: longPressAction) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(style.primary.opacity(0.22))
                        .frame(width: 50, height: 50)
                    Image(systemName: style.icon)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(style.primary)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text("Selected sound")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color(hex: "F5F7FA").opacity(0.62))
                    Text(style.title)
                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color(hex: "F5F7FA"))
                    Text(isPlaying ? "Now soothing • long press to change" : "Tap to use now • long press to change")
                        .font(.caption)
                        .foregroundStyle(Color(hex: "F5F7FA").opacity(0.68))
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color(hex: "F5F7FA").opacity(0.6))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 15)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(.ultraThinMaterial.opacity(0.38))
                    .background(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [style.background.opacity(0.42), Color(hex: "F5F7FA").opacity(0.02)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(style.primary.opacity(0.4), lineWidth: 1)
            )
            .shadow(color: style.primary.opacity(0.28), radius: 18, y: 7)
        }
    }

    private var style: SoundVisualStyle {
        SoundVisualStyle.forSound(sound)
    }
}

private struct PresetCardView: View {
    let title: String
    let subtitle: String
    let icon: String
    let tapAction: () -> Void
    let longPressAction: () -> Void

    var body: some View {
        SoundPressableTile(tapAction: tapAction, longPressAction: longPressAction, longPressDuration: 0.45) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Color(hex: "F5F7FA"))

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color(hex: "F5F7FA"))
                    Text(subtitle)
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(Color(hex: "F5F7FA").opacity(0.72))
                        .lineLimit(1)
                }
                Spacer(minLength: 0)
            }
            .padding(.vertical, 14)
            .padding(.horizontal, 14)
            .background(.ultraThinMaterial.opacity(0.24))
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color(hex: "F5F7FA").opacity(0.06))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color(hex: "F5F7FA").opacity(0.15), lineWidth: 1)
            )
        }
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
            VStack(spacing: 18) {
                SoundPickerSection(
                    sounds: sounds,
                    selectedSoundID: selectedSoundID,
                    onSelect: { selectedSoundID = $0.id }
                )

                VStack(spacing: 14) {
                    HStack {
                        Label("Cry Detection", systemImage: "waveform.badge.mic")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color(hex: "F5F7FA").opacity(0.9))
                        Spacer()
                        Toggle("", isOn: $cryDetectionEnabled)
                            .labelsHidden()
                            .tint(Color(hex: "A2B8FF"))
                    }

                    HStack {
                        Label("Duration", systemImage: "timer")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color(hex: "F5F7FA").opacity(0.9))
                        Spacer()
                        Stepper("\(durationMinutes) min", value: $durationMinutes, in: 1 ... 180)
                            .foregroundStyle(Color(hex: "F5F7FA"))
                            .font(.subheadline.weight(.semibold))
                    }
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(.ultraThinMaterial.opacity(0.3))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Color(hex: "F5F7FA").opacity(0.12), lineWidth: 1)
                )

                Spacer(minLength: 0)
            }
            .padding(20)
            .background(DreamNestTheme.background)
            .navigationTitle("\(preset == .bedtime ? "Sleep" : "Nap") Preset")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        onSave(
                            selectedSoundID,
                            durationMinutes,
                            cryDetectionEnabled,
                            smartResettleEnabled,
                            listeningWindowMinutes,
                            resettleDurationMinutes,
                            maxAutoResettles
                        )
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.large])
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
    @State private var workingSelectionID: String

    init(
        sounds: [SoundDefinition],
        selectedSoundID: String,
        title: String,
        applyButtonTitle: String,
        onSelect: @escaping (SoundDefinition) -> Void,
        onApply: @escaping () -> Void
    ) {
        self.sounds = sounds
        self.selectedSoundID = selectedSoundID
        self.title = title
        self.applyButtonTitle = applyButtonTitle
        self.onSelect = onSelect
        self.onApply = onApply
        _workingSelectionID = State(initialValue: selectedSoundID)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 18) {
                SoundPickerSection(
                    sounds: sounds,
                    selectedSoundID: workingSelectionID,
                    onSelect: { sound in
                        withAnimation(.spring(response: 0.32, dampingFraction: 0.84)) {
                            workingSelectionID = sound.id
                        }
                        onSelect(sound)
                    }
                )

                Button {
                    onApply()
                    dismiss()
                } label: {
                    Text(applyButtonTitle)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(Color(hex: "0E162B"))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: [Color(hex: "F2D0C1"), Color(hex: "E3B6A1")],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        )
                        .shadow(color: Color(hex: "E3B6A1").opacity(0.36), radius: 14, y: 5)
                }
                .buttonStyle(.plain)
            }
            .padding(20)
            .background(DreamNestTheme.background)
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}

private struct SoundPickerSection: View {
    let sounds: [SoundDefinition]
    let selectedSoundID: String
    let onSelect: (SoundDefinition) -> Void

    private let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    var body: some View {
        ScrollView(showsIndicators: false) {
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(sounds, id: \.id) { sound in
                    SoundTileView(sound: sound, isSelected: sound.id == selectedSoundID) {
                        onSelect(sound)
                    }
                }
            }
            .padding(.bottom, 8)
        }
    }
}

private struct SoundTileView: View {
    let sound: SoundDefinition
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            let style = SoundVisualStyle.forSound(sound)
            VStack(alignment: .leading, spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(style.primary.opacity(isSelected ? 0.28 : 0.18))
                        .frame(width: 44, height: 44)
                    Image(systemName: style.icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(style.primary)
                }

                Text(style.title)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color(hex: "F5F7FA"))
                    .lineLimit(1)

                Text(style.subtitle)
                    .font(.caption)
                    .foregroundStyle(Color(hex: "F5F7FA").opacity(0.7))
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity, minHeight: 126, alignment: .leading)
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(.ultraThinMaterial.opacity(0.38))
                    .background(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [style.background.opacity(0.5), Color(hex: "F5F7FA").opacity(0.03)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(isSelected ? style.primary.opacity(0.86) : Color(hex: "F5F7FA").opacity(0.14), lineWidth: isSelected ? 1.4 : 1)
            )
            .shadow(color: style.primary.opacity(isSelected ? 0.34 : 0.14), radius: isSelected ? 18 : 8, y: 5)
            .scaleEffect(isSelected ? 1.015 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.84), value: isSelected)
        }
        .buttonStyle(.plain)
    }
}

private struct SoundPressableTile<Content: View>: View {
    let tapAction: () -> Void
    let longPressAction: () -> Void
    var longPressDuration: Double = 0.5
    @ViewBuilder let content: () -> Content

    @State private var isPressed = false
    @State private var didLongPress = false

    var body: some View {
        content()
            .contentShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .scaleEffect(isPressed ? 0.985 : 1)
            .animation(.easeOut(duration: 0.18), value: isPressed)
            .simultaneousGesture(
                LongPressGesture(minimumDuration: longPressDuration)
                    .onEnded { _ in
                        didLongPress = true
                        longPressAction()
                    }
            )
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        guard !isPressed else { return }
                        isPressed = true
                    }
                    .onEnded { _ in
                        isPressed = false
                    }
            )
            .onTapGesture {
                guard !didLongPress else {
                    didLongPress = false
                    return
                }
                tapAction()
            }
    }
}

private struct SoundVisualStyle {
    let icon: String
    let title: String
    let subtitle: String
    let primary: Color
    let background: Color

    static func forSound(_ sound: SoundDefinition) -> SoundVisualStyle {
        let name = sound.title.lowercased()
        let id = sound.id.lowercased()

        if id.contains("rain") || name.contains("rain") {
            return .init(icon: "cloud.rain.fill", title: "Rain", subtitle: "Soft rainfall", primary: Color(hex: "9AB4D8"), background: Color(hex: "354A62"))
        }
        if id.contains("white") || name.contains("white") {
            return .init(icon: "waveform.path", title: "White Noise", subtitle: "Airy masking hush", primary: Color(hex: "D4DFEA"), background: Color(hex: "4A5363"))
        }
        if id.contains("heart") || name.contains("heart") {
            return .init(icon: "heart.fill", title: "Heartbeat", subtitle: "Steady womb-like rhythm", primary: Color(hex: "E5A8A1"), background: Color(hex: "5B3E4B"))
        }
        if id.contains("brown") || name.contains("brown") {
            return .init(icon: "wave.3.right", title: "Brown Noise", subtitle: "Low ambient wave", primary: Color(hex: "C3AA95"), background: Color(hex: "4A413C"))
        }
        if id.contains("wave") || id.contains("ocean") || name.contains("wave") || name.contains("ocean") {
            return .init(icon: "water.waves", title: "Ocean", subtitle: "Moonlit coastal calm", primary: Color(hex: "93B4CC"), background: Color(hex: "2C475E"))
        }
        if id.contains("lullaby") || name.contains("lullaby") {
            return .init(icon: "music.note", title: "Lullaby", subtitle: "Bedtime melody glow", primary: Color(hex: "C7B3E6"), background: Color(hex: "463C5A"))
        }

        return .init(icon: "sparkles", title: sound.title, subtitle: "Calm baby-safe ambience", primary: Color(hex: "B4BDD3"), background: Color(hex: "39435A"))
    }
}

private struct StatusPill: View {
    let text: String
    let isTriggered: Bool

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(isTriggered ? Color(hex: "E4A890") : Color(hex: "9BC4FF"))
                .frame(width: 7, height: 7)
                .shadow(color: (isTriggered ? Color(hex: "E4A890") : Color(hex: "9BC4FF")).opacity(0.65), radius: 5)

            Text(text)
                .font(.footnote.weight(.medium))
                .foregroundStyle(Color(hex: "F5F7FA").opacity(0.9))
                .lineLimit(1)
                .minimumScaleFactor(0.9)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            Capsule(style: .continuous)
                .fill(Color(hex: "F5F7FA").opacity(0.1))
        )
        .overlay(
            Capsule(style: .continuous)
                .stroke(Color(hex: "F5F7FA").opacity(0.18), lineWidth: 1)
        )
    }
}

private extension Color {
    init(hex: String) {
        let cleaned = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&int)

        let red: UInt64
        let green: UInt64
        let blue: UInt64
        let alpha: UInt64

        switch cleaned.count {
        case 3:
            (alpha, red, green, blue) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (alpha, red, green, blue) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (alpha, red, green, blue) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (alpha, red, green, blue) = (255, 245, 247, 250)
        }

        self.init(
            .sRGB,
            red: Double(red) / 255,
            green: Double(green) / 255,
            blue: Double(blue) / 255,
            opacity: Double(alpha) / 255
        )
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
