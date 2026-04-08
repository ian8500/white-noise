import Foundation

public struct TimerSettings: Codable, Equatable, Sendable {
    public var duration: TimeInterval
    public var fadeDuration: TimeInterval

    public init(duration: TimeInterval = 45 * 60, fadeDuration: TimeInterval = 45) {
        self.duration = duration
        self.fadeDuration = fadeDuration
    }
}

public struct CryResponseSettings: Codable, Equatable, Sendable {
    public var enabled: Bool
    public var volumeBoostStep: Float
    public var timerExtension: TimeInterval
    public var cooldown: TimeInterval

    public init(enabled: Bool = false, volumeBoostStep: Float = 0.08, timerExtension: TimeInterval = 10 * 60, cooldown: TimeInterval = 120) {
        self.enabled = enabled
        self.volumeBoostStep = volumeBoostStep
        self.timerExtension = timerExtension
        self.cooldown = cooldown
    }
}

public struct PremiumState: Codable, Equatable, Sendable {
    public var unlockedSoundIDs: Set<String>

    public init(unlockedSoundIDs: Set<String> = []) {
        self.unlockedSoundIDs = unlockedSoundIDs
    }
}

public struct AppSettings: Codable, Equatable, Sendable {
    public var lastSoundID: String
    public var lastVolume: Float
    public var timer: TimerSettings
    public var cryResponse: CryResponseSettings
    public var premium: PremiumState
    public var maxGainCap: Float

    public init(
        lastSoundID: String = "white-noise",
        lastVolume: Float = 0.35,
        timer: TimerSettings = .init(),
        cryResponse: CryResponseSettings = .init(),
        premium: PremiumState = .init(),
        maxGainCap: Float = 0.75
    ) {
        self.lastSoundID = lastSoundID
        self.lastVolume = lastVolume
        self.timer = timer
        self.cryResponse = cryResponse
        self.premium = premium
        self.maxGainCap = max(0, min(maxGainCap, 1.0))
    }
}

public struct CryDetectionEvent: Codable, Equatable, Sendable, Identifiable {
    public let id: UUID
    public let timestamp: Date
    public let confidence: Float

    public init(id: UUID = UUID(), timestamp: Date = Date(), confidence: Float) {
        self.id = id
        self.timestamp = timestamp
        self.confidence = confidence
    }
}
