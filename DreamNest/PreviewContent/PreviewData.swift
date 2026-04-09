import Foundation

enum PreviewData {
    static let sampleSettings = AppSettings(
        lastSoundID: "pink-noise",
        lastVolume: 0.4,
        timer: .init(duration: 45 * 60, fadeDuration: 60),
        cryResponse: .init(enabled: true, volumeBoostStep: 0.06, timerExtension: 8 * 60, cooldown: 120),
        premium: .init(unlockedSoundIDs: ["white-noise", "pink-noise"]),
        noiseProtection: .init(enabled: true, maxGainCap: 0.72, warningThreshold: 0.68)
    )

    static let sampleCryEvents: [CryDetectionEvent] = [
        .init(timestamp: Date().addingTimeInterval(-900), confidence: 0.83),
        .init(timestamp: Date().addingTimeInterval(-3300), confidence: 0.79)
    ]
}
