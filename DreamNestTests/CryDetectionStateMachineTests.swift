import XCTest
@testable import DreamNest

final class CryDetectionStateMachineTests: XCTestCase {
    func testStateMachineTriggersAfterPersistenceThreshold() {
        let machine = CryDetectionStateMachine(config: .init(persistenceFrames: 3, cooldown: 10))
        let now = Date()

        let frames = (0..<3).map {
            CryHeuristicFrame(rms: 0.03, centroid: 1400, bandEnergyRatio: 0.7, timestamp: now.addingTimeInterval(Double($0) * 0.1))
        }

        let signals = frames.map(machine.process)
        XCTAssertFalse(signals[0].detected)
        XCTAssertFalse(signals[1].detected)
        XCTAssertTrue(signals[2].detected)
    }

    func testCooldownDebouncesAdditionalTriggers() {
        let machine = CryDetectionStateMachine(config: .init(persistenceFrames: 1, cooldown: 60))
        let now = Date()

        let first = machine.process(.init(rms: 0.03, centroid: 1500, bandEnergyRatio: 0.8, timestamp: now))
        let second = machine.process(.init(rms: 0.03, centroid: 1500, bandEnergyRatio: 0.8, timestamp: now.addingTimeInterval(5)))

        XCTAssertTrue(first.detected)
        XCTAssertFalse(second.detected)
    }

    func testUpdatingCooldownAllowsFasterRetrigger() {
        let machine = CryDetectionStateMachine(config: .init(persistenceFrames: 1, cooldown: 120))
        let now = Date()

        let first = machine.process(.init(rms: 0.03, centroid: 1500, bandEnergyRatio: 0.8, timestamp: now))
        machine.updateCooldown(1)
        let second = machine.process(.init(rms: 0.03, centroid: 1500, bandEnergyRatio: 0.8, timestamp: now.addingTimeInterval(2)))

        XCTAssertTrue(first.detected)
        XCTAssertTrue(second.detected)
    }
}
