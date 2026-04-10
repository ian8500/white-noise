import Combine
import XCTest
@testable import DreamNest

@MainActor
final class HomeViewModelConcurrencyTests: XCTestCase {
    func testStoppingDuringPendingQuickStartPreventsPlaybackStateFlip() async {
        let timer = TimerProbe()
        let audio = SlowAudioSpy()
        let viewModel = makeViewModel(audio: audio, timer: timer)

        viewModel.quickStart()
        viewModel.stopPlayback()
        try? await Task.sleep(nanoseconds: 250_000_000)

        XCTAssertFalse(viewModel.isPlaying)
        XCTAssertTrue(timer.startCalls.isEmpty)
    }

    func testInitialIdleTimerStateDoesNotForceAudioStop() async {
        let timer = TimerProbe()
        let audio = SlowAudioSpy()
        _ = makeViewModel(audio: audio, timer: timer)

        await Task.yield()

        XCTAssertEqual(audio.stopCalls, 0)
    }

    private func makeViewModel(audio: SlowAudioSpy, timer: TimerProbe) -> HomeViewModel {
        HomeViewModel(
            catalogService: SoundCatalogService(sounds: SoundDefinition.seededCatalog),
            audio: audio,
            timer: timer,
            store: InMemoryStore(),
            cryService: SilentCryService(),
            safetyPolicy: .init(),
            cryResponseCoordinator: .init()
        )
    }
}

private final class SlowAudioSpy: AudioPlaybackControlling {
    var playbackStatePublisher: AnyPublisher<AudioPlaybackState, Never> { Just(.idle).eraseToAnyPublisher() }
    private(set) var stopCalls = 0

    func configureSession(micModeEnabled: Bool) throws {}

    func play(sound: SoundDefinition, volume: Float) async throws {
        try? await Task.sleep(nanoseconds: 200_000_000)
    }

    func pause() {}
    func resume() {}
    func updateVolume(_ volume: Float, rampDuration: TimeInterval) {}

    func stop(fadeDuration: TimeInterval) async {
        stopCalls += 1
    }
}

private final class TimerProbe: SleepTimerScheduling {
    struct StartCall {
        let duration: TimeInterval
        let fadeDuration: TimeInterval
    }

    private let subject = CurrentValueSubject<SleepTimerState, Never>(.init())
    var statePublisher: AnyPublisher<SleepTimerState, Never> { subject.eraseToAnyPublisher() }
    private(set) var startCalls: [StartCall] = []

    func start(duration: TimeInterval, fadeDuration: TimeInterval) {
        startCalls.append(.init(duration: duration, fadeDuration: fadeDuration))
        subject.send(.init(isRunning: true, startedAt: Date(), remaining: duration, fadeDuration: fadeDuration))
    }

    func extend(by seconds: TimeInterval) {}

    func cancel() {
        subject.send(.init())
    }

    func restoreIfNeeded(referenceDate: Date) {}
}

private final class InMemoryStore: SettingsStoring {
    var settings = AppSettings()
    func load() -> AppSettings { settings }
    func save(_ settings: AppSettings) { self.settings = settings }
    func appendCryEvent(_ event: CryDetectionEvent) {}
    func loadCryEvents(limit: Int) -> [CryDetectionEvent] { [] }
}

private final class SilentCryService: CryDetectionControlling {
    var detectionPublisher: AnyPublisher<CryDetectionSignal, Never> { Empty().eraseToAnyPublisher() }
    func requestPermission() async -> Bool { true }
    func start() throws {}
    func stop() {}
    func updateDetectionThreshold(_ threshold: Float) {}
    func updateCooldown(_ cooldown: TimeInterval) {}
}
