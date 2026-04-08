import XCTest
@testable import DreamNest

final class CryResponseCoordinatorTests: XCTestCase {
    func testCryResponseBoostsVolumeAndExtendsTimer() {
        let coordinator = CryResponseCoordinator()
        let signal = CryDetectionSignal(detected: true, confidence: 0.91, date: Date())
        let settings = CryResponseSettings(enabled: true, volumeBoostStep: 0.1, timerExtension: 120, cooldown: 30)

        let action = coordinator.handle(
            signal: signal,
            isEnabled: true,
            settings: settings,
            currentVolume: 0.4,
            safetyPolicy: NoiseSafetyPolicy(maxGainCap: 0.75)
        )

        XCTAssertEqual(action?.targetVolume, 0.5, accuracy: 0.0001)
        XCTAssertEqual(action?.timerExtension, 120)
        XCTAssertEqual(action?.shouldRecordEvent, true)
    }

    func testCryResponseHonorsCooldown() {
        let coordinator = CryResponseCoordinator()
        let start = Date()
        let settings = CryResponseSettings(enabled: true, volumeBoostStep: 0.1, timerExtension: 120, cooldown: 60)

        _ = coordinator.handle(
            signal: .init(detected: true, confidence: 0.84, date: start),
            isEnabled: true,
            settings: settings,
            currentVolume: 0.5,
            safetyPolicy: NoiseSafetyPolicy(maxGainCap: 0.75)
        )

        let second = coordinator.handle(
            signal: .init(detected: true, confidence: 0.82, date: start.addingTimeInterval(10)),
            isEnabled: true,
            settings: settings,
            currentVolume: 0.6,
            safetyPolicy: NoiseSafetyPolicy(maxGainCap: 0.75)
        )

        XCTAssertNil(second)
    }
}
