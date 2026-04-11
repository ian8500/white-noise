import SwiftUI
import Combine
#if os(iOS)
import UIKit
#endif

struct HomeView: View {
    @StateObject var viewModel: HomeViewModel
    @State private var backgroundBreathing = false
    @State private var editingPreset: PlaybackPreset?

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
            PresetConfigurationSheet(
                preset: preset,
                selectedSoundID: viewModel.quickPresetSound(for: preset).id,
                durationMinutes: Int(viewModel.quickPresetConfiguration(for: preset).duration / 60),
                cryDetectionEnabled: viewModel.quickPresetConfiguration(for: preset).cryModeEnabled,
                sounds: viewModel.catalog,
                onSave: { soundID, minutes, cryEnabled in
                    viewModel.updateQuickPreset(
                        preset,
                        durationMinutes: minutes,
                        cryModeEnabled: cryEnabled,
                        soundID: soundID
                    )
                }
            )
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
                        softHaptic()
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
                PresetCard(
                    title: preset == .bedtime ? "Sleep" : "Nap",
                    subtitle: "\(Int(viewModel.quickPresetConfiguration(for: preset).duration / 60)) min • \(viewModel.quickPresetConfiguration(for: preset).cryModeEnabled ? "Cry On" : "Cry Off")",
                    icon: preset == .bedtime ? "moon.stars.fill" : "cloud.sun.fill",
                    tapAction: {
                        softHaptic()
                        Task { await viewModel.startPreset(preset) }
                    },
                    longPressAction: {
                        softHaptic()
                        editingPreset = preset
                    }
                )
            }
        }
    }

    private var soundSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 14) {
                ForEach(featuredSounds, id: \.id) { sound in
                    SoundCard(
                        sound: sound,
                        isSelected: viewModel.selectedSound.id == sound.id,
                        action: {
                            softHaptic()
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                                viewModel.selectSound(sound)
                            }
                        }
                    )
                }
            }
            .padding(.horizontal, 2)
            .padding(.vertical, 6)
        }
        .frame(height: 110)
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

    private var featuredSounds: [SoundDefinition] {
        let desired = ["rain", "white-noise", "heartbeat", "ocean"]
        let indexed = Dictionary(uniqueKeysWithValues: viewModel.catalog.map { ($0.id.lowercased(), $0) })

        let ordered = desired.compactMap { key in
            indexed.first(where: { $0.key.contains(key) })?.value
        }

        if !ordered.isEmpty {
            return ordered
        }

        return Array(viewModel.catalog.prefix(4))
    }

    private var isRecentlyTriggered: Bool {
        guard let timestamp = viewModel.lastCryDetectionTime else { return false }
        return Date().timeIntervalSince(timestamp) < 90
    }

    private var statusMessage: String {
        isRecentlyTriggered
            ? "Baby stirred — soothing started 🤍"
            : "Listening for your baby 👂"
    }

    private func toggleSleep() {
        softHaptic()
        withAnimation(.easeInOut(duration: 0.35)) {
            if viewModel.isPlaying {
                viewModel.stopPlayback()
            } else {
                viewModel.startDefaultRoutine()
            }
        }
    }

    private func softHaptic() {
#if os(iOS)
        let generator = UIImpactFeedbackGenerator(style: .soft)
        generator.impactOccurred(intensity: 0.85)
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

private struct PresetCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let tapAction: () -> Void
    let longPressAction: () -> Void
    @State private var didLongPress = false

    var body: some View {
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
        .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .onTapGesture {
            if didLongPress {
                didLongPress = false
                return
            }
            tapAction()
        }
        .onLongPressGesture(minimumDuration: 0.5) {
            didLongPress = true
            longPressAction()
        }
    }
}

private struct PresetConfigurationSheet: View {
    let preset: PlaybackPreset
    @State var selectedSoundID: String
    @State var durationMinutes: Int
    @State var cryDetectionEnabled: Bool
    let sounds: [SoundDefinition]
    let onSave: (String, Int, Bool) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Sound") {
                    Picker("Type", selection: $selectedSoundID) {
                        ForEach(sounds, id: \.id) { sound in
                            Text(sound.title).tag(sound.id)
                        }
                    }
                }

                Section("Cry Detection") {
                    Toggle("Enable Cry Detection", isOn: $cryDetectionEnabled)
                }

                Section("Timer") {
                    Stepper(value: $durationMinutes, in: 1 ... 180, step: 1) {
                        Text("Duration: \(durationMinutes) min")
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(DreamNestTheme.background)
            .navigationTitle("\(preset == .bedtime ? "Sleep" : "Nap") Preset")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        onSave(selectedSoundID, durationMinutes, cryDetectionEnabled)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

private struct SoundCard: View {
    let sound: SoundDefinition
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 6) {
                Text(displayEmoji)
                    .font(.title3)
                Text(displayTitle)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
            }
            .foregroundStyle(Color(hex: "F5F7FA").opacity(isSelected ? 1 : 0.86))
            .frame(width: 116, height: 84, alignment: .leading)
            .padding(.horizontal, 12)
            .background(.ultraThinMaterial.opacity(0.28))
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color(hex: "F5F7FA").opacity(isSelected ? 0.1 : 0.05))
            )
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color(hex: "F5F7FA").opacity(isSelected ? 0.35 : 0.14), lineWidth: 1)
            )
            .shadow(color: Color(hex: "E4A890").opacity(isSelected ? 0.3 : 0.08), radius: isSelected ? 14 : 6, y: 4)
            .scaleEffect(isSelected ? 1.03 : 1)
            .animation(.spring(response: 0.35, dampingFraction: 0.82), value: isSelected)
        }
        .buttonStyle(.plain)
    }

    private var displayTitle: String {
        let value = sound.title.lowercased()
        if value.contains("white") { return "White Noise" }
        if value.contains("heart") { return "Heartbeat" }
        if value.contains("ocean") { return "Ocean" }
        if value.contains("rain") { return "Rain" }
        return sound.title
    }

    private var displayEmoji: String {
        let value = sound.title.lowercased()
        if value.contains("white") { return "🌬" }
        if value.contains("heart") { return "❤️" }
        if value.contains("ocean") { return "🌊" }
        if value.contains("rain") { return "🌧" }
        return "🎵"
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
