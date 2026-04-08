import Foundation

public enum FadeCurve {
    /// Equal-power style fade for natural perceived loudness drop.
    public static func gain(remaining: TimeInterval, fadeDuration: TimeInterval) -> Float {
        guard fadeDuration > 0 else { return remaining > 0 ? 1 : 0 }
        if remaining >= fadeDuration { return 1 }
        if remaining <= 0 { return 0 }

        let x = max(0, min(1, remaining / fadeDuration))
        let eased = sin(.pi * 0.5 * x)
        return Float(eased * eased)
    }
}
