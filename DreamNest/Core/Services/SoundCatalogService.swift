import Foundation

public struct SoundCatalogService: SoundCatalogProviding {
    public let sounds: [SoundDefinition]

    public init(sounds: [SoundDefinition] = SoundDefinition.seededCatalog) {
        self.sounds = sounds
    }

    public func sound(id: String) -> SoundDefinition? {
        sounds.first(where: { $0.id == id })
    }
}
