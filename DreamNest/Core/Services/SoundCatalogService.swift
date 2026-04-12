import Foundation

public struct SoundCatalogService: SoundCatalogProviding {
    public let sounds: [SoundDefinition]

    public init(sounds: [SoundDefinition] = SoundDefinition.seededCatalog, bundle: Bundle = .main) {
        self.sounds = sounds.filter { sound in
            bundle.url(forResource: sound.filename, withExtension: "mp3") != nil
            || bundle.url(forResource: sound.filename, withExtension: "wav") != nil
            || bundle.url(forResource: sound.filename, withExtension: "m4a") != nil
        }
    }

    public func sound(id: String) -> SoundDefinition? {
        sounds.first(where: { $0.id == id })
    }
}
