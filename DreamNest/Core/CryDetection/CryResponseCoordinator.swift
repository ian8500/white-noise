import Foundation

public struct CryResponseAction: Equatable {
    public let targetVolume: Float
    public let timerExtension: TimeInterval
    public let shouldRecordEvent: Bool

    public init(targetVolume: Float, timerExtension: TimeInterval, shouldRecordEvent: Bool) {
        self.targetVolume = targetVolume
        self.timerExtension = timerExtension
        self.shouldRecordEvent = shouldRecordEvent
    }
}

public final class CryResponseCoordinator {
    private var lastResponseDate: Date?

    public init() {}

    public func handle(
        signal: CryDetectionSignal,
        isEnabled: Bool,
        settings: CryResponseSettings,
        currentVolume: Float,
        safetyPolicy: NoiseSafetyPolicy
    ) -> CryResponseAction? {
        guard isEnabled, signal.detected else { return nil }

        if let lastResponseDate,
           signal.date.timeIntervalSince(lastResponseDate) < settings.cooldown {
            return nil
        }

        lastResponseDate = signal.date
        let targetVolume = safetyPolicy.clamped(volume: currentVolume + settings.volumeBoostStep)
        return CryResponseAction(
            targetVolume: targetVolume,
            timerExtension: settings.timerExtension,
            shouldRecordEvent: true
        )
    }
}
