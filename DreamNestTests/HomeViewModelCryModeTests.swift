import Combine
import XCTest
@testable import DreamNest

@MainActor
final class HomeViewModelCryModeTests: XCTestCase {
    func testCryDetectionStartsWhiteNoiseForFiveMinutesWhenIdle() async {
        let cryService = CryServiceSpy()
        let audio = AudioSpy()
        let timer = TimerSpy()
        let store = StoreSpy()
        store.settings.cryResponse = .init(enabled: true, volumeBoostStep: 0.08, timerExtension: 120, cooldown: 1)

        let viewModel = HomeViewModel(
            catalogService: SoundCatalogService(sounds: SoundDefinition.seededCatalog),
            audio: audio,
            timer: timer,
            store: store,
            cryService: cryService,
            safetyPolicy: .init(),
            cryResponseCoordinator: .init(),
            playbackSessionStore: PlaybackSessionStoreStub()
        )
        _ = viewModel

        cryService.emit(.init(detected: true, confidence: 0.92))
        await Task.yield()
        await Task.yield()

        XCTAssertEqual(audio.playCalls.last?.sound.id, "white-noise")
        XCTAssertEqual(timer.startCalls.last?.duration, 5 * 60, accuracy: 0.001)
        XCTAssertTrue(viewModel.isPlaying)
    }

    func testCryDetectionExtendsTimerWhenAlreadyPlaying() {
        let cryService = CryServiceSpy()
        let audio = AudioSpy()
        let timer = TimerSpy()
        let store = StoreSpy()
        store.settings.cryResponse = .init(enabled: true, volumeBoostStep: 0.08, timerExtension: 75, cooldown: 1)

        let viewModel = HomeViewModel(
            catalogService: SoundCatalogService(sounds: SoundDefinition.seededCatalog),
            audio: audio,
            timer: timer,
            store: store,
            cryService: cryService,
            safetyPolicy: .init(),
            cryResponseCoordinator: .init(),
            playbackSessionStore: PlaybackSessionStoreStub()
        )
        viewModel.isPlaying = true

        cryService.emit(.init(detected: true, confidence: 0.9))

        XCTAssertEqual(timer.extendCalls.last, 75, accuracy: 0.001)
        XCTAssertTrue(audio.playCalls.isEmpty)
    }

    func testCryDetectionLogsActionsForIdleStart() async {
        let cryService = CryServiceSpy()
        let audio = AudioSpy()
        let timer = TimerSpy()
        let store = StoreSpy()
        store.settings.cryResponse = .init(enabled: true, volumeBoostStep: 0.08, timerExtension: 120, cooldown: 30)

        let viewModel = HomeViewModel(
            catalogService: SoundCatalogService(sounds: SoundDefinition.seededCatalog),
            audio: audio,
            timer: timer,
            store: store,
            cryService: cryService,
            safetyPolicy: .init(),
            cryResponseCoordinator: .init()
        )
        _ = viewModel

        cryService.emit(.init(detected: true, confidence: 0.77, date: .init(timeIntervalSince1970: 1_700_000_000)))
        await Task.yield()
        await Task.yield()

        XCTAssertEqual(store.cryEvents.count, 1)
        XCTAssertEqual(store.cryEvents[0].actions, [.increasedVolume, .startedPlayback])
        XCTAssertEqual(viewModel.recentCryEvents.first?.actionDescription, "Increased volume • Started playback")
    }

    func testCooldownStateTransitionsAfterDetection() async {
        let cryService = CryServiceSpy()
        let audio = AudioSpy()
        let timer = TimerSpy()
        let store = StoreSpy()
        store.settings.cryResponse = .init(enabled: true, volumeBoostStep: 0.08, timerExtension: 120, cooldown: 30)

        var now = Date(timeIntervalSince1970: 2_000)
        let viewModel = HomeViewModel(
            catalogService: SoundCatalogService(sounds: SoundDefinition.seededCatalog),
            audio: audio,
            timer: timer,
            store: store,
            cryService: cryService,
            safetyPolicy: .init(),
            cryResponseCoordinator: .init(),
            dateProvider: { now }
        )
        _ = viewModel

        cryService.emit(.init(detected: true, confidence: 0.88, date: now))
        await Task.yield()

        XCTAssertTrue(viewModel.cryCooldownRemaining > 29)
        XCTAssertTrue(viewModel.cryCooldownStatusLabel.contains("Cooling down"))

        now = now.addingTimeInterval(40)
        timer.state.send(.init(isRunning: false, remaining: 0, fadeDuration: 0))
        await Task.yield()

        XCTAssertEqual(viewModel.cryCooldownStatusLabel, "Ready")
    }
}

private final class AudioSpy: AudioPlaybackControlling {
    struct PlayCall {
        let sound: SoundDefinition
        let volume: Float
    }

    var playbackStatePublisher: AnyPublisher<AudioPlaybackState, Never> {
        Just(.idle).eraseToAnyPublisher()
    }

    private(set) var playCalls: [PlayCall] = []

    func configureSession(micModeEnabled: Bool) throws {}

    func play(sound: SoundDefinition, volume: Float) async throws {
        playCalls.append(.init(sound: sound, volume: volume))
    }

    func pause() {}
    func resume() {}
    func updateVolume(_ volume: Float, rampDuration: TimeInterval) {}
    func stop(fadeDuration: TimeInterval) async {}
}

private final class TimerSpy: SleepTimerScheduling {
    struct StartCall {
        let duration: TimeInterval
        let fadeDuration: TimeInterval
    }

    let state = CurrentValueSubject<SleepTimerState, Never>(.init())
    var statePublisher: AnyPublisher<SleepTimerState, Never> { state.eraseToAnyPublisher() }

    private(set) var startCalls: [StartCall] = []
    private(set) var extendCalls: [TimeInterval] = []

    func start(duration: TimeInterval, fadeDuration: TimeInterval) {
        startCalls.append(.init(duration: duration, fadeDuration: fadeDuration))
    }

    func extend(by seconds: TimeInterval) {
        extendCalls.append(seconds)
    }

    func cancel() {}
    func restoreIfNeeded(referenceDate: Date) {}
}

private final class StoreSpy: SettingsStoring {
    var settings = AppSettings()
    private(set) var cryEvents: [CryDetectionEvent] = []

    func load() -> AppSettings { settings }
    func save(_ settings: AppSettings) { self.settings = settings }
    func appendCryEvent(_ event: CryDetectionEvent) { cryEvents.append(event) }
    func loadCryEvents(limit: Int) -> [CryDetectionEvent] { Array(cryEvents.suffix(limit)) }
    func clearCryEvents() { cryEvents.removeAll() }
}

private final class CryServiceSpy: CryDetectionControlling {
    private let subject = PassthroughSubject<CryDetectionSignal, Never>()

    var detectionPublisher: AnyPublisher<CryDetectionSignal, Never> {
        subject.eraseToAnyPublisher()
    }

    func requestPermission() async -> Bool { true }
    func start() throws {}
    func stop() {}
    func updateDetectionThreshold(_ threshold: Float) {}
    func updateCooldown(_ cooldown: TimeInterval) {}

    func emit(_ signal: CryDetectionSignal) {
        subject.send(signal)
    }
}


private final class PlaybackSessionStoreStub: PlaybackSessionStoring {
    func load() -> PlaybackSessionSnapshot? { nil }
    func save(_ snapshot: PlaybackSessionSnapshot) {}
    func clear() {}
}
