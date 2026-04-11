import Foundation

public struct SmartResettleConfiguration: Equatable, Sendable {
    public var listeningWindow: TimeInterval
    public var resettleDuration: TimeInterval
    public var maxAutoResettles: Int
    public var cooldown: TimeInterval

    public init(
        listeningWindow: TimeInterval = 30 * 60,
        resettleDuration: TimeInterval = 5 * 60,
        maxAutoResettles: Int = 2,
        cooldown: TimeInterval = 3 * 60
    ) {
        self.listeningWindow = max(15 * 60, listeningWindow)
        self.resettleDuration = max(3 * 60, resettleDuration)
        self.maxAutoResettles = max(1, min(maxAutoResettles, 3))
        self.cooldown = max(30, cooldown)
    }
}

public enum SmartResettleMode: Equatable, Sendable {
    case idle
    case playingPreset
    case listeningForResettle
    case autoResettling
    case completed
}

public struct SmartResettleSession: Equatable, Sendable {
    public let preset: PlaybackPreset
    public let sound: SoundDefinition
    public let presetDuration: TimeInterval
    public let sessionStartTime: Date
    public let scheduledTimerEnd: Date
    public let listeningWindowEnd: Date
    public let cryDetectionEnabled: Bool
    public let smartResettleEnabled: Bool
    public let configuration: SmartResettleConfiguration
    public var autoResettleCount: Int
    public var lastAutoResettleAt: Date?
    public var resettleEndTime: Date?
    public var mode: SmartResettleMode

    public init(
        preset: PlaybackPreset,
        sound: SoundDefinition,
        presetDuration: TimeInterval,
        sessionStartTime: Date,
        scheduledTimerEnd: Date,
        cryDetectionEnabled: Bool,
        smartResettleEnabled: Bool = true,
        configuration: SmartResettleConfiguration,
        autoResettleCount: Int = 0,
        lastAutoResettleAt: Date? = nil,
        resettleEndTime: Date? = nil,
        mode: SmartResettleMode = .playingPreset
    ) {
        self.preset = preset
        self.sound = sound
        self.presetDuration = max(60, presetDuration)
        self.sessionStartTime = sessionStartTime
        self.scheduledTimerEnd = scheduledTimerEnd
        self.listeningWindowEnd = scheduledTimerEnd.addingTimeInterval(configuration.listeningWindow)
        self.cryDetectionEnabled = cryDetectionEnabled
        self.smartResettleEnabled = smartResettleEnabled
        self.configuration = configuration
        self.autoResettleCount = autoResettleCount
        self.lastAutoResettleAt = lastAutoResettleAt
        self.resettleEndTime = resettleEndTime
        self.mode = mode
    }

    public var hasResettleCapacity: Bool {
        autoResettleCount < configuration.maxAutoResettles
    }

    public func isInListeningWindow(at date: Date) -> Bool {
        date <= listeningWindowEnd
    }

    public func isCoolingDown(at date: Date) -> Bool {
        guard let lastAutoResettleAt else { return false }
        return date.timeIntervalSince(lastAutoResettleAt) < configuration.cooldown
    }
}
