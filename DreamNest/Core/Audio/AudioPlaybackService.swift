import AVFoundation
import Combine
import MediaPlayer
import Foundation

public final class AudioPlaybackService: NSObject, AudioPlaybackControlling {
    private let state = CurrentValueSubject<AudioPlaybackState, Never>(.idle)
    private var player: AVAudioPlayer?
    private var fadeTask: Task<Void, Never>?
    private var nowPlayingSound: SoundDefinition?

    public var playbackStatePublisher: AnyPublisher<AudioPlaybackState, Never> { state.eraseToAnyPublisher() }

    public override init() {
        super.init()
        registerForInterruptionNotifications()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    public func configureSession() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playback, mode: .default, options: [.mixWithOthers, .allowAirPlay])
        try session.setActive(true)
    }

    public func play(sound: SoundDefinition, volume: Float) async throws {
        state.send(.preparing)
        guard let url = Bundle.main.url(forResource: sound.filename, withExtension: "m4a") else {
            state.send(.failed(message: "Missing asset: \(sound.filename).m4a"))
            return
        }

        let newPlayer = try AVAudioPlayer(contentsOf: url)
        newPlayer.numberOfLoops = -1
        newPlayer.volume = 0
        newPlayer.prepareToPlay()
        newPlayer.play()

        let oldPlayer = player
        player = newPlayer
        nowPlayingSound = sound
        state.send(.playing(soundID: sound.id))
        updateNowPlaying(sound: sound)

        await crossfade(from: oldPlayer, to: newPlayer, targetVolume: volume)
    }

    public func updateVolume(_ volume: Float, rampDuration: TimeInterval) {
        fadeTask?.cancel()
        guard let player else { return }
        fadeTask = Task { [weak player] in
            let start = player?.volume ?? 0
            let steps = max(1, Int(rampDuration / 0.05))
            for i in 1 ... steps {
                try? await Task.sleep(nanoseconds: 50_000_000)
                let t = Float(i) / Float(steps)
                player?.volume = start + (volume - start) * t
            }
        }
    }

    public func stop(fadeDuration: TimeInterval) async {
        guard let player else { return }
        let initial = player.volume
        let steps = max(1, Int(fadeDuration / 0.05))
        for i in 0 ..< steps {
            try? await Task.sleep(nanoseconds: 50_000_000)
            let t = Float(i + 1) / Float(steps)
            player.volume = initial * (1 - t)
        }
        player.stop()
        self.player = nil
        state.send(.idle)
    }

    private func crossfade(from old: AVAudioPlayer?, to new: AVAudioPlayer, targetVolume: Float) async {
        let steps = 12
        let oldInitial = old?.volume ?? 0
        for i in 0 ..< steps {
            try? await Task.sleep(nanoseconds: 40_000_000)
            let t = Float(i + 1) / Float(steps)
            new.volume = targetVolume * t
            old?.volume = oldInitial * (1 - t)
        }
        old?.stop()
    }

    private func registerForInterruptionNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(onAudioSessionInterruption),
            name: AVAudioSession.interruptionNotification,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(onRouteChanged),
            name: AVAudioSession.routeChangeNotification,
            object: nil
        )
    }

    @objc private func onAudioSessionInterruption(_ note: Notification) {
        guard let info = note.userInfo,
              let value = info[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: value)
        else { return }

        switch type {
        case .began:
            player?.pause()
            state.send(.interrupted)
        case .ended:
            player?.play()
            if let id = nowPlayingSound?.id { state.send(.playing(soundID: id)) }
        @unknown default:
            break
        }
    }

    @objc private func onRouteChanged(_ note: Notification) {
        guard let info = note.userInfo,
              let value = info[AVAudioSessionRouteChangeReasonKey] as? UInt,
              let reason = AVAudioSession.RouteChangeReason(rawValue: value)
        else { return }
        if reason == .oldDeviceUnavailable { player?.pause() }
    }

    private func updateNowPlaying(sound: SoundDefinition) {
        MPNowPlayingInfoCenter.default().nowPlayingInfo = [
            MPMediaItemPropertyTitle: sound.title,
            MPNowPlayingInfoPropertyIsLiveStream: false,
            MPNowPlayingInfoPropertyPlaybackRate: 1
        ]
    }
}
