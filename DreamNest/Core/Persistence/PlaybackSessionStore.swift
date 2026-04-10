import Foundation

public struct PlaybackSessionSnapshot: Codable, Equatable, Sendable {
    public var soundID: String
    public var targetVolume: Float
    public var expectedEndDate: Date
    public var micModeEnabled: Bool

    public init(soundID: String, targetVolume: Float, expectedEndDate: Date, micModeEnabled: Bool) {
        self.soundID = soundID
        self.targetVolume = targetVolume
        self.expectedEndDate = expectedEndDate
        self.micModeEnabled = micModeEnabled
    }

    public var remainingDuration: TimeInterval {
        max(0, expectedEndDate.timeIntervalSinceNow)
    }

    public var isStillActive: Bool {
        remainingDuration > 1
    }
}

public protocol PlaybackSessionStoring {
    func load() -> PlaybackSessionSnapshot?
    func save(_ snapshot: PlaybackSessionSnapshot)
    func clear()
}

public final class UserDefaultsPlaybackSessionStore: PlaybackSessionStoring {
    private enum Keys {
        static let sessionSnapshot = "dreamnest.playback.snapshot"
    }

    private let defaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    public func load() -> PlaybackSessionSnapshot? {
        guard let data = defaults.data(forKey: Keys.sessionSnapshot) else { return nil }
        return try? decoder.decode(PlaybackSessionSnapshot.self, from: data)
    }

    public func save(_ snapshot: PlaybackSessionSnapshot) {
        guard let data = try? encoder.encode(snapshot) else { return }
        defaults.set(data, forKey: Keys.sessionSnapshot)
    }

    public func clear() {
        defaults.removeObject(forKey: Keys.sessionSnapshot)
    }
}
