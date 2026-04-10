import SwiftUI
import Combine

struct HomeView: View {
    @StateObject var viewModel: HomeViewModel
    @State private var isVolumeExpanded = true
    @State private var isPresetConfigExpanded = false
    @State private var isCryEventsExpanded = true
    @State private var showStartRoutineDialog = false
    @State private var selectedPresetForQuickControls: PlaybackPreset?
    @State private var suppressNextPresetTap: PlaybackPreset?

    var body: some View {
        ZStack {
            DreamNestTheme.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 18) {
                    header
                    timerHeroCard
                    controlButtons
                    presetButtons
                    ExpandableSettingsCard(title: "Volume", isExpanded: $isVolumeExpanded) {
                        volumeCardContent
                    }
                    ExpandableSettingsCard(title: "Nap & Bedtime Presets", isExpanded: $isPresetConfigExpanded) {
                        presetConfigCardContent
                    }
                    ExpandableSettingsCard(title: "Cry Detection Events", isExpanded: $isCryEventsExpanded) {
                        cryDetectionEventsContent
                    }
                }
                .padding()
            }
        }
        .overlay {
            if showStartRoutineDialog {
                startRoutineDialogOverlay
                    .transition(.opacity.combined(with: .scale(scale: 0.96)))
                    .zIndex(2)
            }
        }
        .overlay {
            if let preset = selectedPresetForQuickControls {
                presetQuickControlsOverlay(for: preset)
                    .transition(.opacity.combined(with: .scale(scale: 0.96)))
                    .zIndex(3)
            }
        }
        .preferredColorScheme(.dark)
        .alert("Safety Guidance", isPresented: .constant(viewModel.warningBanner != nil), actions: {
            Button("OK") { viewModel.warningBanner = nil }
        }, message: {
            Text(viewModel.warningBanner ?? "")
        })
        .animation(.easeInOut(duration: 0.2), value: showStartRoutineDialog)
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


    private var controlButtons: some View {
        VStack(spacing: 10) {
            quickStartButton
            stopButton
        }
    }

    private var quickStartButton: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Start Routine", systemImage: "moon.zzz.fill")
                .font(.title3.weight(.semibold))
            HStack(spacing: 8) {
                Image(systemName: "timer")
                    .font(.caption.weight(.semibold))
                Text("Sleep timer: \(viewModel.formattedTimerDuration)")
                    .font(.footnote.weight(.medium))
                Spacer()
                Text("Long press to adjust")
                    .font(.caption)
                    .foregroundStyle(DreamNestTheme.primaryText.opacity(0.85))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
        .background(DreamNestTheme.accent)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .onTapGesture(perform: viewModel.startDefaultRoutine)
        .onLongPressGesture(minimumDuration: 0.5) {
            showStartRoutineDialog = true
        }
        .accessibilityAddTraits(.isButton)
        .accessibilityHint("Starts your configured routine. Long press to adjust timer and sound.")
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
        let presetSound = viewModel.quickPresetSound(for: preset)
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
                Text("\(presetSound.title) • \(Int(config.duration / 60))m • Cry \(config.cryModeEnabled ? "On" : "Off")")
                    .font(.caption)
                    .foregroundStyle(prominent ? DreamNestTheme.primaryText.opacity(0.85) : DreamNestTheme.secondaryText)
                    .lineLimit(1)
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)

        if prominent {
            Button {
                if suppressNextPresetTap == preset {
                    suppressNextPresetTap = nil
                    return
                }
                Task { await viewModel.startPreset(preset) }
            } label: {
                label
            }
            .buttonStyle(BorderedProminentButtonStyle())
            .onLongPressGesture(minimumDuration: 0.5) {
                suppressNextPresetTap = preset
                selectedPresetForQuickControls = preset
            }
        } else {
            Button {
                if suppressNextPresetTap == preset {
                    suppressNextPresetTap = nil
                    return
                }
                Task { await viewModel.startPreset(preset) }
            } label: {
                label
            }
            .buttonStyle(BorderedButtonStyle())
            .onLongPressGesture(minimumDuration: 0.5) {
                suppressNextPresetTap = preset
                selectedPresetForQuickControls = preset
            }
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
            VStack(alignment: .leading, spacing: 6) {
                Text("Sound")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(DreamNestTheme.secondaryText)
                Menu {
                    ForEach(viewModel.catalog) { sound in
                        Button {
                            viewModel.updateQuickPreset(preset, soundID: sound.id)
                        } label: {
                            if viewModel.quickPresetSound(for: preset).id == sound.id {
                                Label(sound.title, systemImage: "checkmark")
                            } else {
                                Text(sound.title)
                            }
                        }
                    }
                } label: {
                    HStack {
                        Text(viewModel.quickPresetSound(for: preset).title)
                            .lineLimit(1)
                        Spacer()
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(DreamNestTheme.secondaryText)
                    }
                    .font(.footnote.weight(.medium))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 9)
                    .background(DreamNestTheme.background.opacity(0.8))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
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

    private var volumeCardContent: some View {
        Slider(value: Binding(
            get: { Double(viewModel.volume) },
            set: { viewModel.setVolume(Float($0)) }
        ), in: 0 ... 1)
        .accessibilityLabel("Playback volume")
        .accessibilityValue("\(Int(viewModel.volume * 100)) percent")
    }

    private var startRoutineDialogOverlay: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .onTapGesture { showStartRoutineDialog = false }

            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Start Routine Controls")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(DreamNestTheme.primaryText)
                        Text("Set timer and sound before you start.")
                            .font(.footnote)
                            .foregroundStyle(DreamNestTheme.secondaryText)
                    }
                    Spacer()
                    Button {
                        showStartRoutineDialog = false
                    } label: {
                        Image(systemName: "xmark")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(DreamNestTheme.primaryText)
                            .padding(8)
                            .background(DreamNestTheme.background.opacity(0.85))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Sleep Timer")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(DreamNestTheme.secondaryText)
                    HStack(spacing: 8) {
                        timerStepButton(title: "-10m") { viewModel.adjustTimerDuration(minutesDelta: -10) }
                        timerStepButton(title: "-5m") { viewModel.adjustTimerDuration(minutesDelta: -5) }
                        timerStepButton(title: "-1m") { viewModel.adjustTimerDuration(minutesDelta: -1) }
                        Spacer(minLength: 4)
                        timerStepButton(title: "+1m") { viewModel.adjustTimerDuration(minutesDelta: 1) }
                        timerStepButton(title: "+5m") { viewModel.adjustTimerDuration(minutesDelta: 5) }
                        timerStepButton(title: "+10m") { viewModel.adjustTimerDuration(minutesDelta: 10) }
                    }
                    Text("Current timer: \(viewModel.formattedTimerDuration)")
                        .font(.footnote.weight(.medium))
                        .foregroundStyle(DreamNestTheme.primaryText)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Sound")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(DreamNestTheme.secondaryText)
                    ScrollView {
                        VStack(spacing: 8) {
                            ForEach(viewModel.catalog) { sound in
                                Button {
                                    viewModel.selectSound(sound)
                                } label: {
                                    HStack(spacing: 10) {
                                        Text(sound.title)
                                            .lineLimit(1)
                                        Spacer()
                                        if viewModel.selectedSound.id == sound.id {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundStyle(DreamNestTheme.accent)
                                        }
                                    }
                                    .foregroundStyle(DreamNestTheme.primaryText)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 10)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(DreamNestTheme.background.opacity(0.85))
                                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .frame(maxHeight: 240)
                }

                Button("Done") {
                    showStartRoutineDialog = false
                }
                .font(.headline.weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(DreamNestTheme.accent)
                .foregroundStyle(DreamNestTheme.primaryText)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .padding(16)
            .frame(maxWidth: 420)
            .background(DreamNestTheme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(DreamNestTheme.secondaryText.opacity(0.2), lineWidth: 1)
            )
            .padding(.horizontal, 16)
            .accessibilityAddTraits(.isModal)
        }
    }

    private func presetQuickControlsOverlay(for preset: PlaybackPreset) -> some View {
        let config = viewModel.quickPresetConfiguration(for: preset)
        let sound = viewModel.quickPresetSound(for: preset)

        return ZStack {
            Color.black.opacity(0.55)
                .ignoresSafeArea()
                .onTapGesture {
                    selectedPresetForQuickControls = nil
                    suppressNextPresetTap = nil
                }

            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(preset.title) Quick Controls")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(DreamNestTheme.primaryText)
                        Text("Fine-tune duration, sound, and cry response.")
                            .font(.footnote)
                            .foregroundStyle(DreamNestTheme.secondaryText)
                    }
                    Spacer()
                    Button {
                        selectedPresetForQuickControls = nil
                        suppressNextPresetTap = nil
                    } label: {
                        Image(systemName: "xmark")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(DreamNestTheme.primaryText)
                            .padding(8)
                            .background(DreamNestTheme.background.opacity(0.85))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Duration")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(DreamNestTheme.secondaryText)
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
                    Text("Current: \(Int(config.duration / 60)) minutes")
                        .font(.footnote.weight(.medium))
                        .foregroundStyle(DreamNestTheme.primaryText)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Sound")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(DreamNestTheme.secondaryText)
                    Menu {
                        ForEach(viewModel.catalog) { candidate in
                            Button {
                                viewModel.updateQuickPreset(preset, soundID: candidate.id)
                            } label: {
                                if sound.id == candidate.id {
                                    Label(candidate.title, systemImage: "checkmark")
                                } else {
                                    Text(candidate.title)
                                }
                            }
                        }
                    } label: {
                        HStack {
                            Text(sound.title)
                                .lineLimit(1)
                            Spacer()
                            Image(systemName: "chevron.up.chevron.down")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(DreamNestTheme.secondaryText)
                        }
                        .font(.footnote.weight(.medium))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 9)
                        .background(DreamNestTheme.background.opacity(0.8))
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                }

                Toggle("Enable cry response", isOn: Binding(
                    get: { viewModel.quickPresetConfiguration(for: preset).cryModeEnabled },
                    set: { viewModel.updateQuickPreset(preset, cryModeEnabled: $0) }
                ))
                .tint(DreamNestTheme.accent)
                .font(.footnote)

                Button("Done") {
                    selectedPresetForQuickControls = nil
                    suppressNextPresetTap = nil
                }
                .font(.headline.weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(DreamNestTheme.accent)
                .foregroundStyle(DreamNestTheme.primaryText)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .padding(16)
            .frame(maxWidth: 420)
            .background(DreamNestTheme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(DreamNestTheme.secondaryText.opacity(0.2), lineWidth: 1)
            )
            .padding(.horizontal, 16)
            .accessibilityAddTraits(.isModal)
        }
    }


    private var cryDetectionEventsContent: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Recent trigger actions")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(DreamNestTheme.secondaryText)
                Spacer()
                Button("Clear Triggers", role: .destructive, action: viewModel.clearCryEvents)
                    .font(.caption.weight(.semibold))
                    .buttonStyle(.plain)
            }

            if viewModel.recentCryEvents.isEmpty {
                Text("No cry detection events have been recorded yet.")
                    .foregroundStyle(DreamNestTheme.secondaryText)
                    .font(.footnote)
            } else {
                VStack(spacing: 8) {
                    ForEach(viewModel.recentCryEvents) { event in
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: "waveform.and.mic")
                                .foregroundStyle(DreamNestTheme.accent)
                                .padding(.top, 2)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(event.actionDescription)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(DreamNestTheme.primaryText)
                                Text("\(event.timestamp.formatted(date: .abbreviated, time: .shortened)) • Confidence \(Int(event.confidence * 100))%")
                                    .font(.caption)
                                    .foregroundStyle(DreamNestTheme.secondaryText)
                            }
                            Spacer()
                        }
                        .padding(10)
                        .background(DreamNestTheme.background.opacity(0.75))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
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
