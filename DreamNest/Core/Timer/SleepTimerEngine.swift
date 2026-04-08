import Combine
import Foundation

public final class SleepTimerEngine: SleepTimerScheduling {
    private let state = CurrentValueSubject<SleepTimerState, Never>(.init())
    private var ticker: AnyCancellable?
    private var deadline: Date?

    public var statePublisher: AnyPublisher<SleepTimerState, Never> { state.eraseToAnyPublisher() }

    public init() {}

    public func start(duration: TimeInterval, fadeDuration: TimeInterval) {
        let now = Date()
        deadline = now.addingTimeInterval(duration)
        state.send(.init(isRunning: true, startedAt: now, remaining: duration, fadeDuration: fadeDuration))
        startTicker()
    }

    public func extend(by seconds: TimeInterval) {
        guard let deadline else { return }
        self.deadline = deadline.addingTimeInterval(seconds)
        tick()
    }

    public func cancel() {
        ticker?.cancel()
        ticker = nil
        deadline = nil
        state.send(.init())
    }

    public func restoreIfNeeded(referenceDate: Date = Date()) {
        guard let startedAt = state.value.startedAt, state.value.isRunning else { return }
        let elapsed = referenceDate.timeIntervalSince(startedAt)
        if elapsed >= state.value.remaining { cancel() }
    }

    private func startTicker() {
        ticker?.cancel()
        ticker = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.tick()
            }
    }

    private func tick() {
        guard let deadline else { return }
        let remaining = deadline.timeIntervalSinceNow
        if remaining <= 0 {
            cancel()
            return
        }

        let current = state.value
        state.send(.init(isRunning: true, startedAt: current.startedAt, remaining: remaining, fadeDuration: current.fadeDuration))
    }
}
