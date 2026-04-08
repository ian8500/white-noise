import Foundation

public struct EQBand: Codable, Equatable, Sendable {
    public let frequency: Float
    public let gain: Float

    public init(frequency: Float, gain: Float) {
        self.frequency = frequency
        self.gain = gain
    }
}

public struct EQProfile: Codable, Equatable, Sendable {
    public let name: String
    public let preamp: Float
    public let bands: [EQBand]

    public init(name: String, preamp: Float, bands: [EQBand]) {
        self.name = name
        self.preamp = preamp
        self.bands = bands
    }
}

public extension EQProfile {
    static let whiteNoise = EQProfile(name: "White", preamp: -3, bands: [.init(frequency: 250, gain: 0), .init(frequency: 1_000, gain: 0), .init(frequency: 8_000, gain: 0)])
    static let darkNoise = EQProfile(name: "Dark", preamp: -2, bands: [.init(frequency: 250, gain: 2), .init(frequency: 1_000, gain: -1), .init(frequency: 8_000, gain: -2)])
    static let pinkNoise = EQProfile(name: "Pink", preamp: -2, bands: [.init(frequency: 250, gain: 1), .init(frequency: 1_000, gain: 0), .init(frequency: 8_000, gain: -1)])
    static let brownNoise = EQProfile(name: "Brown", preamp: -1, bands: [.init(frequency: 250, gain: 3), .init(frequency: 1_000, gain: -2), .init(frequency: 8_000, gain: -4)])
    static let rain = EQProfile(name: "Rain", preamp: -2, bands: [.init(frequency: 250, gain: -1), .init(frequency: 1_000, gain: 1), .init(frequency: 8_000, gain: 2)])
    static let waves = EQProfile(name: "Waves", preamp: -2, bands: [.init(frequency: 250, gain: 2), .init(frequency: 1_000, gain: 1), .init(frequency: 8_000, gain: -2)])
    static let fire = EQProfile(name: "Fire", preamp: -3, bands: [.init(frequency: 250, gain: 1), .init(frequency: 1_000, gain: 0), .init(frequency: 8_000, gain: 2)])
    static let fan = EQProfile(name: "Fan", preamp: -1, bands: [.init(frequency: 250, gain: 2), .init(frequency: 1_000, gain: -1), .init(frequency: 8_000, gain: -3)])
    static let forest = EQProfile(name: "Forest", preamp: -2, bands: [.init(frequency: 250, gain: -1), .init(frequency: 1_000, gain: 1), .init(frequency: 8_000, gain: 1)])
    static let heartbeat = EQProfile(name: "Heartbeat", preamp: -4, bands: [.init(frequency: 100, gain: 4), .init(frequency: 500, gain: 1), .init(frequency: 8_000, gain: -5)])
}
