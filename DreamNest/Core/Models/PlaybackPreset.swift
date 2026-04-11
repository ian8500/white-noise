import Foundation

public enum PlaybackPreset: String, Codable, CaseIterable, Sendable, Identifiable {
    case nap
    case bedtime

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .nap: "Nap"
        case .bedtime: "Sleep"
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
