import Foundation

public struct NoiseSafetyPolicy: Sendable {
    public let maxGainCap: Float
    public let warningThreshold: Float

    public init(maxGainCap: Float = 0.75, warningThreshold: Float = 0.70) {
        self.maxGainCap = max(0, min(maxGainCap, 1))
        self.warningThreshold = max(0, min(warningThreshold, 1))
    }

    public func clamped(volume: Float) -> Float {
        min(max(0, volume), maxGainCap)
    }

    public func shouldWarn(for volume: Float) -> Bool {
        volume > warningThreshold
    }
}
