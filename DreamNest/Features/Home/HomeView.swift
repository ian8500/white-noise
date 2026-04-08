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
            Text("Sleep support sounds for bedtime routines.")
                .foregroundStyle(DreamNestTheme.secondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var quickStartButton: some View {
        Button(action: viewModel.quickStart) {
            Text("Quick Start")
                .font(.title3.weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(DreamNestTheme.accent)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var volumeCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Volume")
                .foregroundStyle(DreamNestTheme.primaryText)
            Slider(value: Binding(
                get: { Double(viewModel.volume) },
                set: { viewModel.setVolume(Float($0)) }
            ), in: 0 ... 1)
            Text("\(Int(viewModel.timerRemaining))s remaining")
                .foregroundStyle(DreamNestTheme.secondaryText)
                .font(.footnote)
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
        safetyPolicy: .init()
    ))
}

private final class PreviewAudioService: AudioPlaybackControlling {
    var playbackStatePublisher: AnyPublisher<AudioPlaybackState, Never> { Just(.idle).eraseToAnyPublisher() }
    func configureSession() throws {}
    func play(sound: SoundDefinition, volume: Float) async throws {}
    func updateVolume(_ volume: Float, rampDuration: TimeInterval) {}
    func stop(fadeDuration: TimeInterval) async {}
}

private final class PreviewCryService: CryDetectionControlling {
    var detectionPublisher: AnyPublisher<CryDetectionSignal, Never> { Empty().eraseToAnyPublisher() }
    func requestPermission() async -> Bool { true }
    func start() throws {}
    func stop() {}
}
