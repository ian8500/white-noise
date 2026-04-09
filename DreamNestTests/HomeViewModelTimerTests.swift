import Combine
import XCTest
@testable import DreamNest

@MainActor
final class HomeViewModelTimerTests: XCTestCase {
    func testApplyTimerPresetWhilePlayingExtendsTimerToPresetDuration() {
        let timer = TimerSpy()
        let viewModel = makeViewModel(timer: timer)

        viewModel.isPlaying = true
        viewModel.timerRemaining = 15 * 60

        viewModel.applyTimerPreset(minutes: 30)

        XCTAssertEqual(timer.extendCalls.last, 15 * 60, accuracy: 0.001)
    }

    func testAdjustTimerDurationWhilePlayingClampsReductionToOneMinuteRemaining() {
        let timer = TimerSpy()
        let viewModel = makeViewModel(timer: timer)

        viewModel.isPlaying = true
        viewModel.timerRemaining = 2 * 60

        viewModel.adjustTimerDuration(minutesDelta: -50)

        XCTAssertEqual(timer.extendCalls.last, -60, accuracy: 0.001)
    }

    private func makeViewModel(timer: TimerSpy) -> HomeViewModel {
        HomeViewModel(
            catalogService: CatalogStub(),
            audio: AudioStub(),
            timer: timer,
            store: StoreStub(),
            cryService: CryStub(),
            safetyPolicy: .init(),
            cryResponseCoordinator: .init()
        )
    }
}

private struct CatalogStub: SoundCatalogProviding {
    let sounds: [SoundDefinition] = [.seededCatalog[0]]

    func sound(id: String) -> SoundDefinition? {
        sounds.first(where: { $0.id == id })
    }
}

private final class AudioStub: AudioPlaybackControlling {
    var playbackStatePublisher: AnyPublisher<AudioPlaybackState, Never> {
        Just(.idle).eraseToAnyPublisher()
    }

    func configureSession(micModeEnabled: Bool) throws {}
    func play(sound: SoundDefinition, volume: Float) async throws {}
    func pause() {}
    func resume() {}
    func updateVolume(_ volume: Float, rampDuration: TimeInterval) {}
    func stop(fadeDuration: TimeInterval) async {}
}

private final class TimerSpy: SleepTimerScheduling {
    let statePublisher = CurrentValueSubject<SleepTimerState, Never>(.init()).eraseToAnyPublisher()
    private(set) var extendCalls: [TimeInterval] = []

    func start(duration: TimeInterval, fadeDuration: TimeInterval) {}

    func extend(by seconds: TimeInterval) {
        extendCalls.append(seconds)
    }

    func cancel() {}
    func restoreIfNeeded(referenceDate: Date) {}
}

private final class StoreStub: SettingsStoring {
    var settings = AppSettings()

    func load() -> AppSettings { settings }
    func save(_ settings: AppSettings) { self.settings = settings }
    func appendCryEvent(_ event: CryDetectionEvent) {}
    func loadCryEvents(limit: Int) -> [CryDetectionEvent] { [] }
}

private final class CryStub: CryDetectionControlling {
    var detectionPublisher: AnyPublisher<CryDetectionSignal, Never> {
        Empty().eraseToAnyPublisher()
    }

    func requestPermission() async -> Bool { true }
    func start() throws {}
    func stop() {}
}
