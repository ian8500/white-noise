import SwiftUI
import Combine

struct HomeView: View {
    @StateObject var viewModel: HomeViewModel
    @State private var presetDraftName = ""

    var body: some View {
        ZStack {
            DreamNestTheme.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 18) {
                    header
                    quickStartButton
                    presetButtons
                    stopButton
                    cryStatusCard
                    cryEventLogCard
                    recentSoundsCard
                    timerCard
                    volumeCard
                    soundPicker
                    cryModeCard
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


    private var presetButtons: some View {
        HStack(spacing: 8) {
            Button("Start Nap") {
                Task { await viewModel.startPreset(PlaybackPreset.nap) }
            }
            .buttonStyle(.bordered)

            Button("Start Bedtime") {
                Task { await viewModel.startPreset(PlaybackPreset.bedtime) }
            }
            .buttonStyle(.borderedProminent)
        }
        .tint(DreamNestTheme.accent)
        .frame(maxWidth: .infinity, alignment: .leading)
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

    private var routinesCard: some View {
        SettingsCard(title: "Premium Routines") {
            VStack(alignment: .leading, spacing: 10) {
                if let defaultPreset = viewModel.defaultRoutinePreset {
                    Text("Default quick start: \(defaultPreset.name)")
                        .font(.footnote)
                        .foregroundStyle(DreamNestTheme.secondaryText)
                }

                ForEach(Array(viewModel.routinePresets.enumerated()), id: \.element.id) { index, preset in
                    HStack(spacing: 10) {
                        Button {
                            viewModel.startRoutine(preset: preset)
                        } label: {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(preset.name)
                                    .font(.subheadline.weight(.semibold))
                                Text("\(Int(preset.timerDuration / 60))m • \(preset.cryModeEnabled ? "Cry Mode On" : "Cry Mode Off")")
                                    .font(.caption)
                                    .foregroundStyle(DreamNestTheme.secondaryText)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .buttonStyle(.plain)

                        Button {
                            viewModel.renamePreset(id: preset.id, name: "\(preset.name) \(index + 1)")
                        } label: {
                            Image(systemName: "pencil")
                        }
                        .buttonStyle(.plain)

                        Button {
                            viewModel.setDefaultPreset(id: preset.id)
                        } label: {
                            Image(systemName: viewModel.defaultRoutinePresetID == preset.id ? "bolt.fill" : "bolt")
                                .foregroundStyle(DreamNestTheme.accent)
                        }
                        .buttonStyle(.plain)

                        VStack(spacing: 4) {
                            Button {
                                guard index > 0 else { return }
                                viewModel.movePresets(from: IndexSet(integer: index), to: index - 1)
                            } label: {
                                Image(systemName: "chevron.up")
                            }
                            .buttonStyle(.plain)

                            Button {
                                guard index < viewModel.routinePresets.count - 1 else { return }
                                viewModel.movePresets(from: IndexSet(integer: index), to: index + 2)
                            } label: {
                                Image(systemName: "chevron.down")
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .foregroundStyle(DreamNestTheme.primaryText)
                    .padding(10)
                    .background(DreamNestTheme.cardBackground.opacity(0.8))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }

                HStack {
                    TextField("New preset name", text: $presetDraftName)
                        .textFieldStyle(.roundedBorder)
                    Button("Save") {
                        viewModel.saveCurrentAsPreset(named: presetDraftName)
                        presetDraftName = ""
                    }
                }
            }
        }
    }

    private var timerCard: some View {
        SettingsCard(title: "Sleep Timer") {
            VStack(alignment: .leading, spacing: 4) {
                Text(viewModel.timerCountdownTitle)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(DreamNestTheme.primaryText)
                Text(viewModel.timerCountdownSubtitle)
                    .font(.footnote)
                    .foregroundStyle(DreamNestTheme.secondaryText)
            }
            .padding(.vertical, 2)

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

    private var volumeCard: some View {
        SettingsCard(title: "Volume") {
            Slider(value: Binding(
                get: { Double(viewModel.volume) },
                set: { viewModel.setVolume(Float($0)) }
            ), in: 0 ... 1)
            .accessibilityLabel("Playback volume")
            .accessibilityValue("\(Int(viewModel.volume * 100)) percent")
        }
    }

    private var soundPicker: some View {
        SettingsCard(title: "Sound") {
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
    }

    private var cryModeCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Cry Response Mode")
                    .foregroundStyle(DreamNestTheme.primaryText)
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
        .padding()
        .background(DreamNestTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var cryStatusCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Cry Response Status")
                .foregroundStyle(DreamNestTheme.primaryText)
            cryStatusRow(title: "Monitoring", value: viewModel.cryMonitoringStatusLabel)
            cryStatusRow(title: "Last detection", value: formattedDate(viewModel.lastCryDetectionTime))
            cryStatusRow(title: "Last confidence", value: formattedConfidence(viewModel.lastCryConfidence))
            cryStatusRow(title: "Cooldown", value: viewModel.cryCooldownStatusLabel)
            cryStatusRow(title: "Last action", value: viewModel.lastCryActionSummary)
        }
        .padding()
        .background(DreamNestTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var cryEventLogCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Recent Cry Events")
                .foregroundStyle(DreamNestTheme.primaryText)
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

    private var recentSoundsCard: some View {
        SettingsCard(title: "Recent") {
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

private struct SettingsCard<Content: View>: View {
    let title: String
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .foregroundStyle(DreamNestTheme.primaryText)
            content
        }
        .padding()
        .background(DreamNestTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
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
}
