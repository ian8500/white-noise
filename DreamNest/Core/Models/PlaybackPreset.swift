import Foundation

public enum PlaybackPreset: String, Codable, CaseIterable, Sendable {
    case nap
    case bedtime

    public var title: String {
        switch self {
        case .nap: "Nap"
        case .bedtime: "Bedtime"
        }
    }

    public var defaultDuration: TimeInterval {
        switch self {
        case .nap: 30 * 60
        case .bedtime: 30 * 60
        }
    }

    public var defaultCryModeEnabled: Bool {
        switch self {
        case .nap:
            return true
        case .bedtime:
            return false
        }
    }
}
