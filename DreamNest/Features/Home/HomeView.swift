import SwiftUI
import Combine

struct HomeView: View {
    @StateObject var viewModel: HomeViewModel
    @State private var isCryStatusExpanded = false
    @State private var isCryEventsExpanded = false
    @State private var isRecentExpanded = false
    @State private var isTimerExpanded = true
    @State private var isVolumeExpanded = true
    @State private var isSoundExpanded = true
    @State private var isPresetConfigExpanded = false
    @State private var isCryModeExpanded = false

    var body: some View {
        ZStack {
            DreamNestTheme.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 18) {
                    header
                    timerHeroCard
                    quickStartButton
                    presetButtons
                    ExpandableSettingsCard(title: "Nap & Bedtime Presets", isExpanded: $isPresetConfigExpanded) {
                        presetConfigCardContent
                    }
                    stopButton
                    ExpandableSettingsCard(title: "Sleep Timer Controls", isExpanded: $isTimerExpanded) {
                        timerCardContent
                    }
                    ExpandableSettingsCard(title: "Volume", isExpanded: $isVolumeExpanded) {
                        volumeCardContent
                    }
                    ExpandableSettingsCard(title: "Sound", isExpanded: $isSoundExpanded) {
                        soundPickerContent
                    }
                    ExpandableSettingsCard(title: "Recent", isExpanded: $isRecentExpanded) {
                        recentSoundsCardContent
                    }
                    ExpandableSettingsCard(title: "Cry Response Mode", isExpanded: $isCryModeExpanded) {
                        cryModeCardContent
                    }
                    ExpandableSettingsCard(title: "Cry Response Status", isExpanded: $isCryStatusExpanded) {
                        cryStatusCardContent
                    }
                    ExpandableSettingsCard(title: "Recent Cry Events", isExpanded: $isCryEventsExpanded) {
                        cryEventLogCardContent
                    }
                }
                .padding()
            }
        }
        .preferredColorScheme(.dark)
        .alert("Safety Guidance", isPresented: .constant(viewModel.warningBanner != nil), actions: {
            Button("OK") { viewModel.warningBanner = nil }
        }, message: {
            Text(viewModel.warningBanner ?? "")
        })
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("DreamNest")
                .font(.largeTitle.weight(.bold))
                .foregroundStyle(DreamNestTheme.primaryText)
            Text("Premium white noise for calm, safer bedtimes.")
                .foregroundStyle(DreamNestTheme.secondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("DreamNest. Premium white noise for calmer bedtimes.")
    }

    private var quickStartButton: some View {
        Button(action: viewModel.startDefaultRoutine) {
            Label("Start Routine", systemImage: "moon.zzz.fill")
                .font(.title3.weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(DreamNestTheme.accent)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityHint("Starts your default routine preset, or current settings if no default is set.")
    }

    private var timerHeroCard: some View {
        HStack(alignment: .center, spacing: 14) {
            ZStack {
                Circle()
                    .fill(DreamNestTheme.accent.opacity(0.16))
                    .frame(width: 52, height: 52)
                Image(systemName: viewModel.isPlaying ? "timer.circle.fill" : "timer.circle")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(DreamNestTheme.accent)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(viewModel.timerCountdownTitle)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(DreamNestTheme.primaryText)
                Text(viewModel.timerCountdownSubtitle)
                    .font(.footnote)
                    .foregroundStyle(DreamNestTheme.secondaryText)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(DreamNestTheme.cardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(DreamNestTheme.accent.opacity(0.28), lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Sleep timer status. \(viewModel.timerCountdownTitle). \(viewModel.timerCountdownSubtitle)")
    }


    private var presetButtons: some View {
        HStack(spacing: 10) {
            quickPresetButton(for: .nap, prominent: false)
            quickPresetButton(for: .bedtime, prominent: true)
        }
        .tint(DreamNestTheme.accent)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private func quickPresetButton(for preset: PlaybackPreset, prominent: Bool) -> some View {
        let config = viewModel.quickPresetConfiguration(for: preset)
        let label = HStack(alignment: .center, spacing: 10) {
            ZStack {
                Circle()
                    .fill((prominent ? DreamNestTheme.primaryText : DreamNestTheme.accent).opacity(prominent ? 0.2 : 0.14))
                    .frame(width: 34, height: 34)
                Image(systemName: preset == .nap ? "sun.min.fill" : "moon.fill")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(prominent ? DreamNestTheme.primaryText : DreamNestTheme.accent)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Start \(preset.title)")
                    .font(.subheadline.weight(.semibold))
                Text("\(Int(config.duration / 60))m • Cry \(config.cryModeEnabled ? "On" : "Off")")
                    .font(.caption)
                    .foregroundStyle(prominent ? DreamNestTheme.primaryText.opacity(0.85) : DreamNestTheme.secondaryText)
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)

        if prominent {
            Button {
                Task { await viewModel.startPreset(preset) }
            } label: {
                label
            }
            .buttonStyle(BorderedProminentButtonStyle())
        } else {
            Button {
                Task { await viewModel.startPreset(preset) }
            } label: {
                label
            }
            .buttonStyle(BorderedButtonStyle())
        }
    }

    private var presetConfigCardContent: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Tune your Quick Start buttons with preferred durations and cry response behavior.")
                .font(.footnote)
                .foregroundStyle(DreamNestTheme.secondaryText)
            presetConfigRow(for: .nap)
            presetConfigRow(for: .bedtime)
        }
    }

    private func presetConfigRow(for preset: PlaybackPreset) -> some View {
        let config = viewModel.quickPresetConfiguration(for: preset)
        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(preset.title)
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Text("\(Int(config.duration / 60)) minutes")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(DreamNestTheme.secondaryText)
            }
            HStack(spacing: 8) {
                timerStepButton(title: "-5m") {
                    let updated = max(1, Int(config.duration / 60) - 5)
                    viewModel.updateQuickPreset(preset, durationMinutes: updated)
                }
                timerStepButton(title: "-1m") {
                    let updated = max(1, Int(config.duration / 60) - 1)
                    viewModel.updateQuickPreset(preset, durationMinutes: updated)
                }
                timerStepButton(title: "+1m") {
                    viewModel.updateQuickPreset(preset, durationMinutes: Int(config.duration / 60) + 1)
                }
                timerStepButton(title: "+5m") {
                    viewModel.updateQuickPreset(preset, durationMinutes: Int(config.duration / 60) + 5)
                }
            }
            Toggle("Enable cry response", isOn: Binding(
                get: { viewModel.quickPresetConfiguration(for: preset).cryModeEnabled },
                set: { viewModel.updateQuickPreset(preset, cryModeEnabled: $0) }
            ))
            .tint(DreamNestTheme.accent)
            .font(.footnote)
        }
        .padding(12)
        .background(DreamNestTheme.cardBackground.opacity(0.65))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func timerStepButton(title: String, action: @escaping () -> Void) -> some View {
        Button(title, action: action)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(DreamNestTheme.background.opacity(0.8))
            .clipShape(Capsule())
            .foregroundStyle(DreamNestTheme.primaryText)
    }

    private var stopButton: some View {
        Button(action: viewModel.stopPlayback) {
            Label("Stop", systemImage: "stop.fill")
                .font(.headline.weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(DreamNestTheme.cardBackground.opacity(0.95))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(DreamNestTheme.secondaryText.opacity(0.3), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .disabled(!viewModel.isPlaying)
        .opacity(viewModel.isPlaying ? 1 : 0.55)
        .foregroundStyle(DreamNestTheme.primaryText)
        .accessibilityHint("Stops audio playback and cancels the active timer.")
    }

    private var timerCardContent: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Adjust duration for your next playback session or while audio is running.")
                .font(.footnote)
                .foregroundStyle(DreamNestTheme.secondaryText)

            HStack {
                timerPresetButton("60m", minutes: 60)
                timerPresetButton("30m", minutes: 30)
                timerPresetButton("15m", minutes: 15)
            }
            HStack {
                timerAdjustButton("-10m", minutesDelta: -10)
                timerAdjustButton("-5m", minutesDelta: -5)
                timerAdjustButton("-1m", minutesDelta: -1)
            }
            HStack {
                timerAdjustButton("+10m", minutesDelta: 10)
                timerAdjustButton("+5m", minutesDelta: 5)
                timerAdjustButton("+1m", minutesDelta: 1)
            }
        }
    }

    private func timerPresetButton(_ title: String, minutes: Int) -> some View {
        ChipButton(title: title) { viewModel.applyTimerPreset(minutes: minutes) }
            .accessibilityLabel("Set timer to \(minutes) minutes")
    }

    private func timerAdjustButton(_ title: String, minutesDelta: Int) -> some View {
        ChipButton(title: title) { viewModel.adjustTimerDuration(minutesDelta: minutesDelta) }
            .accessibilityLabel("\(minutesDelta >= 0 ? "Increase" : "Decrease") timer by \(abs(minutesDelta)) minutes")
    }

    private var volumeCardContent: some View {
        Slider(value: Binding(
            get: { Double(viewModel.volume) },
            set: { viewModel.setVolume(Float($0)) }
        ), in: 0 ... 1)
        .accessibilityLabel("Playback volume")
        .accessibilityValue("\(Int(viewModel.volume * 100)) percent")
    }

    private var soundPickerContent: some View {
        ForEach(viewModel.catalog) { sound in
            Button {
                viewModel.selectSound(sound)
            } label: {
                HStack {
                    Text(sound.title)
                    Spacer()
                    Button {
                        viewModel.toggleFavorite(sound)
                    } label: {
                        Image(systemName: viewModel.isFavorite(sound) ? "star.fill" : "star")
                            .foregroundStyle(DreamNestTheme.accent)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(viewModel.isFavorite(sound) ? "Remove favorite" : "Add favorite")

                    if viewModel.selectedSound.id == sound.id {
                        Image(systemName: "checkmark.circle.fill")
                    }
                }
                .foregroundStyle(DreamNestTheme.primaryText)
                .padding(10)
                .background(DreamNestTheme.cardBackground.opacity(0.8))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .buttonStyle(.plain)
            .accessibilityHint("Select \(sound.title) sound.")
        }
    }

    private var cryModeCardContent: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Enable smart soothing response")
                    .foregroundStyle(DreamNestTheme.secondaryText)
                Spacer()
                Toggle("", isOn: Binding(
                    get: { viewModel.cryModeEnabled },
                    set: { viewModel.toggleCryMode($0) }
                ))
                .labelsHidden()
                .accessibilityLabel("Cry response mode")
            }
            Text("On-device detection only")
                .foregroundStyle(DreamNestTheme.secondaryText)
                .font(.footnote)
        }
    }

    private var cryStatusCardContent: some View {
        VStack(alignment: .leading, spacing: 10) {
            cryStatusRow(title: "Monitoring", value: viewModel.cryMonitoringStatusLabel)
            cryStatusRow(title: "Last detection", value: formattedDate(viewModel.lastCryDetectionTime))
            cryStatusRow(title: "Last confidence", value: formattedConfidence(viewModel.lastCryConfidence))
            cryStatusRow(title: "Cooldown", value: viewModel.cryCooldownStatusLabel)
            cryStatusRow(title: "Last action", value: viewModel.lastCryActionSummary)
        }
    }

    private var cryEventLogCardContent: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Last detections and actions")
                    .font(.footnote)
                    .foregroundStyle(DreamNestTheme.secondaryText)
                Spacer()
                if !viewModel.recentCryEvents.isEmpty {
                    Button("Clear") {
                        viewModel.clearCryEvents()
                    }
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.red.opacity(0.9))
                }
            }
            if viewModel.recentCryEvents.isEmpty {
                Text("Cry responses will appear here with confidence and actions.")
                    .foregroundStyle(DreamNestTheme.secondaryText)
                    .font(.footnote)
            } else {
                ForEach(viewModel.recentCryEvents.prefix(6)) { event in
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(formattedDate(event.timestamp)) • \(formattedConfidence(event.confidence))")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(DreamNestTheme.primaryText)
                        Text(event.actionDescription)
                            .font(.footnote)
                            .foregroundStyle(DreamNestTheme.secondaryText)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 4)
                }
            }
        }
    }

    private func cryStatusRow(title: String, value: String) -> some View {
        HStack(alignment: .top) {
            Text(title)
                .foregroundStyle(DreamNestTheme.secondaryText)
            Spacer()
            Text(value)
                .foregroundStyle(DreamNestTheme.primaryText)
                .multilineTextAlignment(.trailing)
        }
        .font(.footnote)
    }

    private func formattedDate(_ date: Date?) -> String {
        guard let date else { return "Not yet" }
        return date.formatted(date: .omitted, time: .shortened)
    }

    private func formattedConfidence(_ confidence: Float?) -> String {
        guard let confidence else { return "Not available" }
        return "\(Int((confidence * 100).rounded()))%"
    }

    private var recentSoundsCardContent: some View {
        Group {
            if viewModel.recentSounds.isEmpty {
                Text("Your last selected sounds appear here.")
                    .foregroundStyle(DreamNestTheme.secondaryText)
                    .font(.footnote)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(viewModel.recentSounds) { sound in
                            ChipButton(title: sound.title) { viewModel.selectSound(sound) }
                        }
                    }
                }
            }
        }
    }
}

private struct ExpandableSettingsCard<Content: View>: View {
    let title: String
    @Binding var isExpanded: Bool
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(spacing: 8) {
                    Text(title)
                        .font(.headline)
                    Spacer()
                    Image(systemName: isExpanded ? "chevron.up.circle.fill" : "chevron.down.circle.fill")
                        .font(.title3)
                        .foregroundStyle(DreamNestTheme.accent)
                }
                .foregroundStyle(DreamNestTheme.primaryText)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("\(title). \(isExpanded ? "Expanded" : "Collapsed")")
            .accessibilityHint("Double tap to \(isExpanded ? "collapse" : "expand") section.")

            if isExpanded {
                content
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding()
        .background(DreamNestTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(DreamNestTheme.secondaryText.opacity(0.16), lineWidth: 1)
        )
    }
}

private struct ChipButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(title, action: action)
            .foregroundStyle(DreamNestTheme.primaryText)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(DreamNestTheme.cardBackground.opacity(0.9))
            .clipShape(Capsule())
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
