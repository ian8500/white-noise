import Foundation

public struct SoundDefinition: Identifiable, Codable, Equatable, Sendable {
    public enum Category: String, Codable, CaseIterable, Sendable {
        case noise
        case nature
        case ambience
        case mechanical
    }

    public let id: String
    public let title: String
    public let category: Category
    public let filename: String
    public let defaultEQProfile: EQProfile
    public let isPremium: Bool
    public let artworkKey: String

    public init(
        id: String,
        title: String,
        category: Category,
        filename: String,
        defaultEQProfile: EQProfile,
        isPremium: Bool,
        artworkKey: String
    ) {
        self.id = id
        self.title = title
        self.category = category
        self.filename = filename
        self.defaultEQProfile = defaultEQProfile
        self.isPremium = isPremium
        self.artworkKey = artworkKey
    }
}

public extension SoundDefinition {
    static let seededCatalog: [SoundDefinition] = [
        .init(id: "white-noise", title: "White Noise", category: .noise, filename: "noise_white_loop", defaultEQProfile: .whiteNoise, isPremium: false, artworkKey: "artwork_white_noise"),
        .init(id: "dark-noise", title: "Dark Noise", category: .noise, filename: "noise_dark_loop", defaultEQProfile: .darkNoise, isPremium: false, artworkKey: "artwork_dark_noise"),
        .init(id: "pink-noise", title: "Pink Noise", category: .noise, filename: "noise_pink_loop", defaultEQProfile: .pinkNoise, isPremium: false, artworkKey: "artwork_pink_noise"),
        .init(id: "brown-noise", title: "Brown Noise", category: .noise, filename: "noise_brown_loop", defaultEQProfile: .brownNoise, isPremium: false, artworkKey: "artwork_brown_noise"),
        .init(id: "rain", title: "Rain", category: .nature, filename: "nature_rain_loop", defaultEQProfile: .rain, isPremium: false, artworkKey: "artwork_rain"),
        .init(id: "waves", title: "Waves", category: .nature, filename: "nature_waves_loop", defaultEQProfile: .waves, isPremium: false, artworkKey: "artwork_waves"),
        .init(id: "fire", title: "Fire", category: .nature, filename: "nature_fire_loop", defaultEQProfile: .fire, isPremium: true, artworkKey: "artwork_fire"),
        .init(id: "fan", title: "Fan", category: .mechanical, filename: "ambient_fan_loop", defaultEQProfile: .fan, isPremium: false, artworkKey: "artwork_fan"),
        .init(id: "forest", title: "Forest", category: .nature, filename: "nature_forest_loop", defaultEQProfile: .forest, isPremium: true, artworkKey: "artwork_forest"),
        .init(id: "heartbeat", title: "Heartbeat Ambience", category: .ambience, filename: "ambient_heartbeat_loop", defaultEQProfile: .heartbeat, isPremium: true, artworkKey: "artwork_heartbeat")
    ]
}
