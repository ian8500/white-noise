import Foundation

public struct TimerSettings: Codable, Equatable, Sendable {
    public var duration: TimeInterval
    public var fadeDuration: TimeInterval

    public init(duration: TimeInterval = 30 * 60, fadeDuration: TimeInterval = 60) {
        self.duration = duration
        self.fadeDuration = fadeDuration
    }
}


public enum CryComfortMode: String, Codable, CaseIterable, Equatable, Sendable {
    case gentle
    case balanced
    case responsive

    public var title: String {
        switch self {
        case .gentle: return "Gentle"
        case .balanced: return "Balanced"
        case .responsive: return "Responsive"
        }
    }

    public var threshold: Float {
        switch self {
        case .gentle: return 0.78
        case .balanced: return 0.68
        case .responsive: return 0.58
        }
    }

    public var helperDescription: String {
        switch self {
        case .gentle:
            return "Waits a little longer before replaying sound, for a softer, less reactive approach."
        case .balanced:
            return "A measured middle ground that gives your little one a moment, then helps them settle again."
        case .responsive:
            return "Reacts sooner to crying and restarts comfort more quickly for extra reassurance."
        }
    }
}

public struct CryResponseSettings: Codable, Equatable, Sendable {
    public var enabled: Bool
    public var volumeBoostStep: Float
    public var timerExtension: TimeInterval
    public var cooldown: TimeInterval
    public var detectionThreshold: Float
    public var comfortMode: CryComfortMode
    public var hasSeenOnboarding: Bool

    public init(enabled: Bool = false, volumeBoostStep: Float = 0.08, timerExtension: TimeInterval = 10 * 60, cooldown: TimeInterval = 30, detectionThreshold: Float = 0.68, comfortMode: CryComfortMode = .balanced, hasSeenOnboarding: Bool = false) {
        self.enabled = enabled
        self.volumeBoostStep = volumeBoostStep
        self.timerExtension = timerExtension
        self.cooldown = cooldown
        self.detectionThreshold = max(0.4, min(detectionThreshold, 0.95))
        self.comfortMode = comfortMode
        self.hasSeenOnboarding = hasSeenOnboarding
    }

    enum CodingKeys: String, CodingKey {
        case enabled
        case volumeBoostStep
        case timerExtension
        case cooldown
        case detectionThreshold
        case comfortMode
        case hasSeenOnboarding
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        enabled = try container.decodeIfPresent(Bool.self, forKey: .enabled) ?? false
        volumeBoostStep = try container.decodeIfPresent(Float.self, forKey: .volumeBoostStep) ?? 0.08
        timerExtension = try container.decodeIfPresent(TimeInterval.self, forKey: .timerExtension) ?? 10 * 60
        cooldown = try container.decodeIfPresent(TimeInterval.self, forKey: .cooldown) ?? 30
        let threshold = try container.decodeIfPresent(Float.self, forKey: .detectionThreshold) ?? 0.68
        detectionThreshold = max(0.4, min(threshold, 0.95))
        comfortMode = try container.decodeIfPresent(CryComfortMode.self, forKey: .comfortMode) ?? .balanced
        hasSeenOnboarding = try container.decodeIfPresent(Bool.self, forKey: .hasSeenOnboarding) ?? false
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

public struct QuickStartPresetSettings: Codable, Equatable, Sendable {
    public var duration: TimeInterval
    public var cryModeEnabled: Bool
    public var soundID: String?
    public var smartResettleEnabled: Bool
    public var listeningWindow: TimeInterval
    public var resettleDuration: TimeInterval
    public var maxAutoResettles: Int

    public init(
        duration: TimeInterval,
        cryModeEnabled: Bool,
        soundID: String? = nil,
        smartResettleEnabled: Bool = false,
        listeningWindow: TimeInterval = 30 * 60,
        resettleDuration: TimeInterval = 5 * 60,
        maxAutoResettles: Int = 2
    ) {
        self.duration = max(60, duration)
        self.cryModeEnabled = cryModeEnabled
        self.soundID = soundID
        self.smartResettleEnabled = smartResettleEnabled
        self.listeningWindow = max(15 * 60, listeningWindow)
        self.resettleDuration = max(3 * 60, resettleDuration)
        self.maxAutoResettles = max(1, min(maxAutoResettles, 3))
    }

    enum CodingKeys: String, CodingKey {
        case duration
        case cryModeEnabled
        case soundID
        case smartResettleEnabled
        case listeningWindow
        case resettleDuration
        case maxAutoResettles
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        duration = max(60, try container.decodeIfPresent(TimeInterval.self, forKey: .duration) ?? 60)
        cryModeEnabled = try container.decodeIfPresent(Bool.self, forKey: .cryModeEnabled) ?? false
        soundID = try container.decodeIfPresent(String.self, forKey: .soundID)
        smartResettleEnabled = try container.decodeIfPresent(Bool.self, forKey: .smartResettleEnabled) ?? false
        listeningWindow = max(15 * 60, try container.decodeIfPresent(TimeInterval.self, forKey: .listeningWindow) ?? 30 * 60)
        resettleDuration = max(3 * 60, try container.decodeIfPresent(TimeInterval.self, forKey: .resettleDuration) ?? 5 * 60)
        maxAutoResettles = max(1, min(try container.decodeIfPresent(Int.self, forKey: .maxAutoResettles) ?? 2, 3))
    }

    public static func `default`(for preset: PlaybackPreset) -> QuickStartPresetSettings {
        .init(duration: preset.defaultDuration, cryModeEnabled: preset.defaultCryModeEnabled)
    }
}

public struct RoutinePreset: Codable, Equatable, Identifiable, Sendable {
    public let id: UUID
    public var name: String
    public var soundID: String
    public var volume: Float
    public var timerDuration: TimeInterval
    public var cryModeEnabled: Bool

    public init(
        id: UUID = UUID(),
        name: String,
        soundID: String,
        volume: Float,
        timerDuration: TimeInterval,
        cryModeEnabled: Bool
    ) {
        self.id = id
        self.name = name
        self.soundID = soundID
        self.volume = max(0, min(volume, 1.0))
        self.timerDuration = max(60, timerDuration)
        self.cryModeEnabled = cryModeEnabled
    }

    public static func seededDefaults(using settings: AppSettings) -> [RoutinePreset] {
        [
            .init(name: "Nap", soundID: settings.lastSoundID, volume: settings.lastVolume, timerDuration: 30 * 60, cryModeEnabled: false),
            .init(name: "Bedtime", soundID: settings.lastSoundID, volume: settings.lastVolume, timerDuration: 30 * 60, cryModeEnabled: settings.cryResponse.enabled),
            .init(name: "Night Rescue", soundID: "white-noise", volume: min(0.55, max(settings.lastVolume, 0.4)), timerDuration: 30 * 60, cryModeEnabled: true)
        ]
    }
}

public struct AppSettings: Codable, Equatable, Sendable {
    public var lastSoundID: String
    public var lastVolume: Float
    public var favoriteSoundIDs: Set<String>
    public var recentSoundIDs: [String]
    public var timer: TimerSettings
    public var cryResponse: CryResponseSettings
    public var premium: PremiumState
    public var noiseProtection: NoiseProtectionSettings
    public var routinePresets: [RoutinePreset]
    public var defaultRoutinePresetID: UUID?
    public var quickStartPresets: [String: QuickStartPresetSettings]

    public init(
        lastSoundID: String = "white-noise",
        lastVolume: Float = 0.35,
        favoriteSoundIDs: Set<String> = [],
        recentSoundIDs: [String] = [],
        timer: TimerSettings = .init(),
        cryResponse: CryResponseSettings = .init(),
        premium: PremiumState = .init(),
        noiseProtection: NoiseProtectionSettings = .init(),
        routinePresets: [RoutinePreset] = [],
        defaultRoutinePresetID: UUID? = nil,
        quickStartPresets: [String: QuickStartPresetSettings] = [:]
    ) {
        self.lastSoundID = lastSoundID
        self.lastVolume = lastVolume
        self.favoriteSoundIDs = favoriteSoundIDs
        self.recentSoundIDs = recentSoundIDs
        self.timer = timer
        self.cryResponse = cryResponse
        self.premium = premium
        self.noiseProtection = noiseProtection
        self.routinePresets = routinePresets
        self.defaultRoutinePresetID = defaultRoutinePresetID
        self.quickStartPresets = quickStartPresets
    }

    enum CodingKeys: String, CodingKey {
        case lastSoundID
        case lastVolume
        case favoriteSoundIDs
        case recentSoundIDs
        case timer
        case cryResponse
        case premium
        case noiseProtection
        case routinePresets
        case defaultRoutinePresetID
        case quickStartPresets
        case maxGainCap
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        lastSoundID = try container.decodeIfPresent(String.self, forKey: .lastSoundID) ?? "white-noise"
        lastVolume = try container.decodeIfPresent(Float.self, forKey: .lastVolume) ?? 0.35
        favoriteSoundIDs = try container.decodeIfPresent(Set<String>.self, forKey: .favoriteSoundIDs) ?? []
        recentSoundIDs = try container.decodeIfPresent([String].self, forKey: .recentSoundIDs) ?? []
        timer = try container.decodeIfPresent(TimerSettings.self, forKey: .timer) ?? .init()
        cryResponse = try container.decodeIfPresent(CryResponseSettings.self, forKey: .cryResponse) ?? .init()
        premium = try container.decodeIfPresent(PremiumState.self, forKey: .premium) ?? .init()

        if let modern = try container.decodeIfPresent(NoiseProtectionSettings.self, forKey: .noiseProtection) {
            noiseProtection = modern
        } else {
            let legacyMax = try container.decodeIfPresent(Float.self, forKey: .maxGainCap) ?? 0.75
            noiseProtection = .init(maxGainCap: legacyMax)
        }

        routinePresets = try container.decodeIfPresent([RoutinePreset].self, forKey: .routinePresets) ?? []
        defaultRoutinePresetID = try container.decodeIfPresent(UUID.self, forKey: .defaultRoutinePresetID)
        quickStartPresets = try container.decodeIfPresent([String: QuickStartPresetSettings].self, forKey: .quickStartPresets) ?? [:]
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(lastSoundID, forKey: .lastSoundID)
        try container.encode(lastVolume, forKey: .lastVolume)
        try container.encode(favoriteSoundIDs, forKey: .favoriteSoundIDs)
        try container.encode(recentSoundIDs, forKey: .recentSoundIDs)
        try container.encode(timer, forKey: .timer)
        try container.encode(cryResponse, forKey: .cryResponse)
        try container.encode(premium, forKey: .premium)
        try container.encode(noiseProtection, forKey: .noiseProtection)
        try container.encode(routinePresets, forKey: .routinePresets)
        try container.encodeIfPresent(defaultRoutinePresetID, forKey: .defaultRoutinePresetID)
        try container.encode(quickStartPresets, forKey: .quickStartPresets)
    }
}

public struct CryDetectionEvent: Codable, Equatable, Sendable, Identifiable {
    public enum EventType: String, Codable, Equatable, Sendable {
        case cryDetected
        case autoResettleStarted
        case autoResettleEnded
        case listeningWindowExpired
        case sessionManuallyStopped
        case legacyCryResponse
    }

    public enum Action: String, Codable, Equatable, Sendable, CaseIterable {
        case startedPlayback
        case increasedVolume
        case extendedTimer
    }

    public let id: UUID
    public let timestamp: Date
    public let confidence: Float
    public let actions: [Action]
    public let eventType: EventType
    public let presetName: String?
    public let soundID: String?
    public let soundTitle: String?
    public let resettleDuration: TimeInterval?

    public init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        confidence: Float,
        actions: [Action] = [],
        eventType: EventType = .legacyCryResponse,
        presetName: String? = nil,
        soundID: String? = nil,
        soundTitle: String? = nil,
        resettleDuration: TimeInterval? = nil
    ) {
        self.id = id
        self.timestamp = timestamp
        self.confidence = confidence
        self.actions = actions
        self.eventType = eventType
        self.presetName = presetName
        self.soundID = soundID
        self.soundTitle = soundTitle
        self.resettleDuration = resettleDuration
    }

    enum CodingKeys: String, CodingKey {
        case id
        case timestamp
        case confidence
        case actions
        case eventType
        case presetName
        case soundID
        case soundTitle
        case resettleDuration
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        timestamp = try container.decodeIfPresent(Date.self, forKey: .timestamp) ?? Date()
        confidence = try container.decodeIfPresent(Float.self, forKey: .confidence) ?? 0
        actions = try container.decodeIfPresent([Action].self, forKey: .actions) ?? []
        eventType = try container.decodeIfPresent(EventType.self, forKey: .eventType) ?? .legacyCryResponse
        presetName = try container.decodeIfPresent(String.self, forKey: .presetName)
        soundID = try container.decodeIfPresent(String.self, forKey: .soundID)
        soundTitle = try container.decodeIfPresent(String.self, forKey: .soundTitle)
        resettleDuration = try container.decodeIfPresent(TimeInterval.self, forKey: .resettleDuration)
    }
}
