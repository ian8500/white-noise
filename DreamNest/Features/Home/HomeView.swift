import SwiftUI
import Combine

struct HomeView: View {
    @StateObject var viewModel: HomeViewModel
    @State private var isVolumeExpanded = true
    @State private var isCryEventsExpanded = true
    @State private var showStartRoutineDialog = false
    @State private var suppressNextStartRoutineTap = false
    @State private var selectedPresetForQuickControls: PlaybackPreset?
    @State private var suppressNextPresetTap: PlaybackPreset?
    @State private var pressedQuickPreset: PlaybackPreset?

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
        .onTapGesture {
            if suppressNextStartRoutineTap {
                suppressNextStartRoutineTap = false
                return
            }
            viewModel.startDefaultRoutine()
        }
        .onLongPressGesture(minimumDuration: 0.5) {
            suppressNextStartRoutineTap = true
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
        .frame(maxWidth: .infinity)
        .tint(DreamNestTheme.accent)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private func quickPresetButton(for preset: PlaybackPreset, prominent: Bool) -> some View {
        let config = viewModel.quickPresetConfiguration(for: preset)
        let presetSound = viewModel.quickPresetSound(for: preset)
        let isPressed = pressedQuickPreset == preset
        let label = VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 10) {
                ZStack {
                    Circle()
                        .fill((prominent ? DreamNestTheme.primaryText : DreamNestTheme.accent).opacity(prominent ? 0.2 : 0.14))
                        .frame(width: 38, height: 38)
                    Image(systemName: preset == .nap ? "sun.min.fill" : "moon.fill")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(prominent ? DreamNestTheme.primaryText : DreamNestTheme.accent)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Start \(preset.title)")
                        .font(.title3.weight(.semibold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.9)
                    Text(presetSound.title)
                        .font(.subheadline.weight(.medium))
                        .lineLimit(1)
                        .minimumScaleFactor(0.9)
                        .foregroundStyle(prominent ? DreamNestTheme.primaryText.opacity(0.88) : DreamNestTheme.secondaryText)
                }
                Spacer(minLength: 0)
            }

            HStack(spacing: 8) {
                Label("\(Int(config.duration / 60)) min", systemImage: "timer")
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)

                Label(config.cryModeEnabled ? "Cry On" : "Cry Off", systemImage: config.cryModeEnabled ? "waveform.and.mic" : "waveform.slash")
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)

                Spacer(minLength: 0)

                Text("Hold")
                    .lineLimit(1)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        Capsule(style: .continuous)
                            .fill((prominent ? DreamNestTheme.primaryText : DreamNestTheme.accent).opacity(0.16))
                    )
                    .foregroundStyle(prominent ? DreamNestTheme.primaryText.opacity(0.9) : DreamNestTheme.accent)
            }
            .font(.caption.weight(.semibold))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 13)
        .padding(.vertical, 13)
        label
            .foregroundStyle(prominent ? DreamNestTheme.primaryText : DreamNestTheme.primaryText)
            .frame(maxWidth: .infinity, minHeight: 124, alignment: .topLeading)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(prominent ? DreamNestTheme.accent : DreamNestTheme.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(prominent ? DreamNestTheme.accent.opacity(0.35) : DreamNestTheme.accent.opacity(0.26), lineWidth: 1)
            )
            .scaleEffect(isPressed ? 0.985 : 1)
            .shadow(color: DreamNestTheme.accent.opacity(prominent ? 0.24 : 0.10), radius: prominent ? 10 : 6, y: 3)
            .animation(.easeOut(duration: 0.12), value: isPressed)
            .contentShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .onTapGesture {
                if suppressNextPresetTap == preset {
                    suppressNextPresetTap = nil
                    return
                }
                Task { await viewModel.startPreset(preset) }
            }
            .simultaneousGesture(
                LongPressGesture(minimumDuration: 0.5)
                    .onEnded { _ in
                        suppressNextPresetTap = preset
                        pressedQuickPreset = nil
                        selectedPresetForQuickControls = preset
                    }
            )
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        pressedQuickPreset = preset
                    }
                    .onEnded { _ in
                        pressedQuickPreset = nil
                    }
            )
            .accessibilityAddTraits(.isButton)
            .accessibilityHint("Tap to start \(preset.title). Long press for quick controls.")
    }

    private func timerStepButton(title: String, action: @escaping () -> Void) -> some View {
        Button(title, action: action)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(DreamNestTheme.elevatedControlBackground)
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
        modalOverlayContainer(dismissAction: { showStartRoutineDialog = false }) {
            dialogHeader(
                title: "Start Routine Controls",
                subtitle: "Set timer and sound before you start.",
                dismissAction: { showStartRoutineDialog = false }
            )

            VStack(alignment: .leading, spacing: 8) {
                dialogSectionTitle("Sleep Timer")
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
                dialogSectionTitle("Sound")
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
                                .background(DreamNestTheme.elevatedControlBackground)
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .frame(maxHeight: 220)
            }

            dialogDoneButton {
                showStartRoutineDialog = false
            }
        }
    }

    private func presetQuickControlsOverlay(for preset: PlaybackPreset) -> some View {
        let config = viewModel.quickPresetConfiguration(for: preset)
        let sound = viewModel.quickPresetSound(for: preset)

        return modalOverlayContainer(dismissAction: {
            selectedPresetForQuickControls = nil
            suppressNextPresetTap = nil
        }) {
            dialogHeader(
                title: "\(preset.title) Quick Controls",
                subtitle: "Fine-tune duration, sound, and cry response.",
                dismissAction: {
                    selectedPresetForQuickControls = nil
                    suppressNextPresetTap = nil
                }
            )

            VStack(alignment: .leading, spacing: 8) {
                dialogSectionTitle("Duration")
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
                dialogSectionTitle("Sound")
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
                    .background(DreamNestTheme.elevatedControlBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
            }

            Toggle("Enable cry response", isOn: Binding(
                get: { viewModel.quickPresetConfiguration(for: preset).cryModeEnabled },
                set: { viewModel.updateQuickPreset(preset, cryModeEnabled: $0) }
            ))
            .tint(DreamNestTheme.accent)
            .font(.footnote)

            Spacer(minLength: 0)

            dialogDoneButton {
                selectedPresetForQuickControls = nil
                suppressNextPresetTap = nil
            }
        }
    }

    @ViewBuilder
    private func modalOverlayContainer<Content: View>(
        dismissAction: @escaping () -> Void,
        @ViewBuilder content: () -> Content
    ) -> some View {
        ZStack {
            Color.black.opacity(0.55)
                .ignoresSafeArea()
                .onTapGesture(perform: dismissAction)

            VStack(alignment: .leading, spacing: 14) {
                content()
            }
            .padding(18)
            .frame(maxWidth: 440)
            .frame(height: 470, alignment: .top)
            .background(DreamNestTheme.modalBackground)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(DreamNestTheme.secondaryText.opacity(0.2), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.25), radius: 20, y: 10)
            .padding(.horizontal, 16)
            .accessibilityAddTraits(.isModal)
        }
    }

    private func dialogHeader(title: String, subtitle: String, dismissAction: @escaping () -> Void) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(DreamNestTheme.primaryText)
                Text(subtitle)
                    .font(.footnote)
                    .foregroundStyle(DreamNestTheme.secondaryText)
            }
            Spacer()
            Button(action: dismissAction) {
                Image(systemName: "xmark")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(DreamNestTheme.primaryText)
                    .padding(8)
                    .background(DreamNestTheme.elevatedControlBackground)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
        }
    }

    private func dialogSectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.caption.weight(.semibold))
            .foregroundStyle(DreamNestTheme.secondaryText)
    }

    private func dialogDoneButton(action: @escaping () -> Void) -> some View {
        Button("Done", action: action)
            .font(.headline.weight(.semibold))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(DreamNestTheme.accent)
            .foregroundStyle(DreamNestTheme.primaryText)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
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
