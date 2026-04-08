import XCTest
@testable import DreamNest

final class FadeCurveTests: XCTestCase {
    func testFadeCurveReturnsOneBeforeFadeWindow() {
        XCTAssertEqual(FadeCurve.gain(remaining: 120, fadeDuration: 30), 1, accuracy: 0.0001)
    }

    func testFadeCurveApproachesZeroAtEnd() {
        XCTAssertEqual(FadeCurve.gain(remaining: 0, fadeDuration: 30), 0, accuracy: 0.0001)
    }

    func testFadeCurveIsMonotonicInFadeWindow() {
        let g1 = FadeCurve.gain(remaining: 25, fadeDuration: 30)
        let g2 = FadeCurve.gain(remaining: 15, fadeDuration: 30)
        let g3 = FadeCurve.gain(remaining: 5, fadeDuration: 30)
        XCTAssertGreaterThan(g1, g2)
        XCTAssertGreaterThan(g2, g3)
    }
}
