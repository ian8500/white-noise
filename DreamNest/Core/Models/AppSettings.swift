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

public struct NoiseProtectionSettings: Codable, Equatable, Sendable {
    public var enabled: Bool
    public var maxGainCap: Float
    public var warningThreshold: Float

    public init(enabled: Bool = true, maxGainCap: Float = 0.75, warningThreshold: Float = 0.70) {
        self.enabled = enabled
        self.maxGainCap = max(0, min(maxGainCap, 1.0))
        self.warningThreshold = max(0, min(warningThreshold, 1.0))
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
    public var noiseProtection: NoiseProtectionSettings

    public init(
        lastSoundID: String = "white-noise",
        lastVolume: Float = 0.35,
        timer: TimerSettings = .init(),
        cryResponse: CryResponseSettings = .init(),
        premium: PremiumState = .init(),
        noiseProtection: NoiseProtectionSettings = .init()
    ) {
        self.lastSoundID = lastSoundID
        self.lastVolume = lastVolume
        self.timer = timer
        self.cryResponse = cryResponse
        self.premium = premium
        self.noiseProtection = noiseProtection
    }

    enum CodingKeys: String, CodingKey {
        case lastSoundID
        case lastVolume
        case timer
        case cryResponse
        case premium
        case noiseProtection
        case maxGainCap
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        lastSoundID = try container.decodeIfPresent(String.self, forKey: .lastSoundID) ?? "white-noise"
        lastVolume = try container.decodeIfPresent(Float.self, forKey: .lastVolume) ?? 0.35
        timer = try container.decodeIfPresent(TimerSettings.self, forKey: .timer) ?? .init()
        cryResponse = try container.decodeIfPresent(CryResponseSettings.self, forKey: .cryResponse) ?? .init()
        premium = try container.decodeIfPresent(PremiumState.self, forKey: .premium) ?? .init()

        if let modern = try container.decodeIfPresent(NoiseProtectionSettings.self, forKey: .noiseProtection) {
            noiseProtection = modern
        } else {
            let legacyMax = try container.decodeIfPresent(Float.self, forKey: .maxGainCap) ?? 0.75
            noiseProtection = .init(maxGainCap: legacyMax)
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(lastSoundID, forKey: .lastSoundID)
        try container.encode(lastVolume, forKey: .lastVolume)
        try container.encode(timer, forKey: .timer)
        try container.encode(cryResponse, forKey: .cryResponse)
        try container.encode(premium, forKey: .premium)
        try container.encode(noiseProtection, forKey: .noiseProtection)
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
