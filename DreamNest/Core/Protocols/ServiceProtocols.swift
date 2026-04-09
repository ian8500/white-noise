import AVFoundation
import Combine
import Foundation

public protocol AudioPlaybackControlling: AnyObject {
    var playbackStatePublisher: AnyPublisher<AudioPlaybackState, Never> { get }
    func configureSession(micModeEnabled: Bool) throws
    func play(sound: SoundDefinition, volume: Float) async throws
    func pause()
    func resume()
    func updateVolume(_ volume: Float, rampDuration: TimeInterval)
    func stop(fadeDuration: TimeInterval) async
}

public protocol SoundCatalogProviding {
    var sounds: [SoundDefinition] { get }
    func sound(id: String) -> SoundDefinition?
}

public protocol SettingsStoring {
    func load() -> AppSettings
    func save(_ settings: AppSettings)
    func appendCryEvent(_ event: CryDetectionEvent)
    func loadCryEvents(limit: Int) -> [CryDetectionEvent]
}

public protocol SleepTimerScheduling: AnyObject {
    var statePublisher: AnyPublisher<SleepTimerState, Never> { get }
    func start(duration: TimeInterval, fadeDuration: TimeInterval)
    func extend(by seconds: TimeInterval)
    func cancel()
    func restoreIfNeeded(referenceDate: Date)
}

public protocol CryDetectionControlling: AnyObject {
    var detectionPublisher: AnyPublisher<CryDetectionSignal, Never> { get }
    func requestPermission() async -> Bool
    func start() throws
    func stop()
    func updateDetectionThreshold(_ threshold: Float)
    func updateCooldown(_ cooldown: TimeInterval)
}

public struct CryDetectionSignal: Equatable, Sendable {
    public let detected: Bool
    public let confidence: Float
    public let date: Date

    public init(detected: Bool, confidence: Float, date: Date = Date()) {
        self.detected = detected
        self.confidence = confidence
        self.date = date
    }
}

public enum AudioPlaybackState: Equatable {
    case idle
    case preparing
    case playing(soundID: String)
    case interrupted
    case failed(message: String)
}

public struct SleepTimerState: Equatable, Sendable {
    public let isRunning: Bool
    public let startedAt: Date?
    public let remaining: TimeInterval
    public let fadeDuration: TimeInterval

    public init(isRunning: Bool = false, startedAt: Date? = nil, remaining: TimeInterval = 0, fadeDuration: TimeInterval = 0) {
        self.isRunning = isRunning
        self.startedAt = startedAt
        self.remaining = remaining
        self.fadeDuration = fadeDuration
    }
}
