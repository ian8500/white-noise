import SwiftUI
import Combine

struct HomeView: View {
    @StateObject var viewModel: HomeViewModel

    var body: some View {
        ZStack {
            DreamNestTheme.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 18) {
                    header
                    quickStartButton
                    stopButton
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
        Button(action: viewModel.quickStart) {
            Label("Start Sleep Session", systemImage: "moon.zzz.fill")
                .font(.title3.weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(DreamNestTheme.accent)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityHint("Starts the selected sound with your configured timer.")
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


    private var timerCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Sleep Timer")
                .foregroundStyle(DreamNestTheme.primaryText)

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
        .padding()
        .background(DreamNestTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func timerPresetButton(_ title: String, minutes: Int) -> some View {
        Button(title) { viewModel.applyTimerPreset(minutes: minutes) }
            .foregroundStyle(DreamNestTheme.primaryText)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(DreamNestTheme.cardBackground.opacity(0.9))
            .clipShape(Capsule())
            .accessibilityLabel("Set timer to \(minutes) minutes")
    }

    private func timerAdjustButton(_ title: String, minutesDelta: Int) -> some View {
        Button(title) { viewModel.adjustTimerDuration(minutesDelta: minutesDelta) }
            .foregroundStyle(DreamNestTheme.primaryText)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(DreamNestTheme.cardBackground.opacity(0.9))
            .clipShape(Capsule())
            .accessibilityLabel("\(minutesDelta >= 0 ? "Increase" : "Decrease") timer by \(abs(minutesDelta)) minutes")
    }

    private var volumeCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Volume")
                .foregroundStyle(DreamNestTheme.primaryText)
            Slider(value: Binding(
                get: { Double(viewModel.volume) },
                set: { viewModel.setVolume(Float($0)) }
            ), in: 0 ... 1)
            .accessibilityLabel("Playback volume")
            .accessibilityValue("\(Int(viewModel.volume * 100)) percent")
        }
        .padding()
        .background(DreamNestTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var soundPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Sound")
                .foregroundStyle(DreamNestTheme.primaryText)
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
        .padding()
        .background(DreamNestTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var cryModeCard: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("Cry Response Mode")
                    .foregroundStyle(DreamNestTheme.primaryText)
                Text("On-device detection only")
                    .foregroundStyle(DreamNestTheme.secondaryText)
                    .font(.footnote)
            }
            Spacer()
            Toggle("", isOn: Binding(
                get: { viewModel.cryModeEnabled },
                set: { viewModel.toggleCryMode($0) }
            ))
            .labelsHidden()
            .accessibilityLabel("Cry response mode")
        }
        .padding()
        .background(DreamNestTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var recentSoundsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Recent")
                .foregroundStyle(DreamNestTheme.primaryText)

            if viewModel.recentSounds.isEmpty {
                Text("Your last selected sounds appear here.")
                    .foregroundStyle(DreamNestTheme.secondaryText)
                    .font(.footnote)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(viewModel.recentSounds) { sound in
                            Button(sound.title) { viewModel.selectSound(sound) }
                                .foregroundStyle(DreamNestTheme.primaryText)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(DreamNestTheme.cardBackground.opacity(0.9))
                                .clipShape(Capsule())
                        }
                    }
                }
            }
        }
        .padding()
        .background(DreamNestTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

#Preview {
    HomeView(viewModel: .init(
        catalogService: SoundCatalogService(),
        audio: PreviewAudioService(),
        timer: SleepTimerEngine(),
        store: UserDefaultsSettingsStore(defaults: .standard),
        cryService: PreviewCryService(),
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
}
