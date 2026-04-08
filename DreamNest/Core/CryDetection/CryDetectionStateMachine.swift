import Foundation

public struct CryHeuristicFrame: Sendable {
    public let rms: Float
    public let centroid: Float
    public let bandEnergyRatio: Float
    public let timestamp: Date

    public init(rms: Float, centroid: Float, bandEnergyRatio: Float, timestamp: Date = Date()) {
        self.rms = rms
        self.centroid = centroid
        self.bandEnergyRatio = bandEnergyRatio
        self.timestamp = timestamp
    }
}

public final class CryDetectionStateMachine {
    public struct Config: Sendable {
        public var rmsThreshold: Float
        public var centroidThresholdHz: Float
        public var bandEnergyThreshold: Float
        public var persistenceFrames: Int
        public var cooldown: TimeInterval

        public init(rmsThreshold: Float = 0.018, centroidThresholdHz: Float = 900, bandEnergyThreshold: Float = 0.42, persistenceFrames: Int = 10, cooldown: TimeInterval = 120) {
            self.rmsThreshold = rmsThreshold
            self.centroidThresholdHz = centroidThresholdHz
            self.bandEnergyThreshold = bandEnergyThreshold
            self.persistenceFrames = persistenceFrames
            self.cooldown = cooldown
        }
    }

    private let config: Config
    private var highConfidenceCount = 0
    private var lastTriggerDate: Date?

    public init(config: Config = .init()) {
        self.config = config
    }

    public func process(_ frame: CryHeuristicFrame) -> CryDetectionSignal {
        if let lastTriggerDate,
           frame.timestamp.timeIntervalSince(lastTriggerDate) < config.cooldown {
            return .init(detected: false, confidence: 0, date: frame.timestamp)
        }

        let amplitudeScore = min(1, frame.rms / config.rmsThreshold)
        let centroidScore = min(1, frame.centroid / config.centroidThresholdHz)
        let bandScore = min(1, frame.bandEnergyRatio / config.bandEnergyThreshold)
        let confidence = max(0, min(1, 0.45 * amplitudeScore + 0.3 * centroidScore + 0.25 * bandScore))

        if confidence >= 0.78 {
            highConfidenceCount += 1
        } else {
            highConfidenceCount = max(0, highConfidenceCount - 1)
        }

        if highConfidenceCount >= config.persistenceFrames {
            lastTriggerDate = frame.timestamp
            highConfidenceCount = 0
            return .init(detected: true, confidence: confidence, date: frame.timestamp)
        }

        return .init(detected: false, confidence: confidence, date: frame.timestamp)
    }
}
