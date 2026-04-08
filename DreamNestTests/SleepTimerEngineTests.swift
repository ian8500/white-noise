import Combine
import XCTest
@testable import DreamNest

final class SleepTimerEngineTests: XCTestCase {
    private var cancellables = Set<AnyCancellable>()

    func testStartPublishesRunningState() {
        let engine = SleepTimerEngine()
        let expectation = expectation(description: "timer running")

        engine.statePublisher
            .dropFirst()
            .sink { state in
                if state.isRunning {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)

        engine.start(duration: 10, fadeDuration: 3)
        waitForExpectations(timeout: 1)
    }

    func testExtendIncreasesRemaining() {
        let engine = SleepTimerEngine()
        engine.start(duration: 10, fadeDuration: 2)

        let before = captureLatest(from: engine)
        engine.extend(by: 15)
        let after = captureLatest(from: engine)

        XCTAssertGreaterThan(after.remaining, before.remaining)
    }

    private func captureLatest(from engine: SleepTimerEngine) -> SleepTimerState {
        var latest = SleepTimerState()
        let semaphore = DispatchSemaphore(value: 0)
        let cancellable = engine.statePublisher
            .prefix(1)
            .sink { value in
                latest = value
                semaphore.signal()
            }
        _ = semaphore.wait(timeout: .now() + 0.5)
        cancellable.cancel()
        return latest
    }
}
