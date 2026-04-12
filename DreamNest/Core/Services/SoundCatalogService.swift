import Foundation

public struct SoundCatalogService: SoundCatalogProviding {
    private static let supportedExtensions = ["mp3", "wav", "m4a"]
    private static let bundledSubdirectories: [String?] = [nil, "Audio", "Resources/Audio"]

    public let sounds: [SoundDefinition]

    public init(sounds: [SoundDefinition] = SoundDefinition.seededCatalog, bundle: Bundle = .main) {
        let availableSounds = sounds.filter { sound in
            Self.resolveURL(for: sound.filename, in: bundle) != nil
        }

        self.sounds = availableSounds.isEmpty ? sounds : availableSounds
    }

    public func sound(id: String) -> SoundDefinition? {
        sounds.first(where: { $0.id == id })
    }

    private static func resolveURL(for filename: String, in bundle: Bundle) -> URL? {
        let fileBase = (filename as NSString).deletingPathExtension
        let explicitExtension = (filename as NSString).pathExtension
        let candidateExtensions = explicitExtension.isEmpty ? supportedExtensions : [explicitExtension]

        for ext in candidateExtensions {
            for subdirectory in bundledSubdirectories {
                if let url = bundle.url(forResource: fileBase, withExtension: ext, subdirectory: subdirectory) {
                    return url
                }
            }
        }

        return nil
    }
}
