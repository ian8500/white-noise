import AVFoundation
import Combine
import Foundation
import MediaPlayer

public final class AudioPlaybackService: NSObject, AudioPlaybackControlling {
    private let state = CurrentValueSubject<AudioPlaybackState, Never>(.idle)
    private var player: AVAudioPlayer?
    private var fadeTask: Task<Void, Never>?
    private var nowPlayingSound: SoundDefinition?

    public var playbackStatePublisher: AnyPublisher<AudioPlaybackState, Never> { state.eraseToAnyPublisher() }

    public override init() {
        super.init()
        registerForInterruptionNotifications()
        configureRemoteCommands()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    public func configureSession() throws {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playback, mode: .default, options: [.allowAirPlay, .allowBluetoothA2DP])
            try session.setActive(true)
            print("[Audio] ✅ Session configured. category=\(session.category.rawValue), mode=\(session.mode.rawValue), route=\(session.currentRoute)")
        } catch {
            print("[Audio] ❌ Session configuration failed: \(error.localizedDescription)")
            throw error
        }
    }

    public func play(sound: SoundDefinition, volume: Float) async throws {
        state.send(.preparing)
        let url = resolveBundledSoundURL(filename: sound.filename)

        guard let url else {
            let message = "Missing bundled audio asset for '\(sound.filename)'. Expected one of: test_white_noise.mp3 / .wav at Resources/Audio/."
            print("[Audio] ❌ \(message)")
            state.send(.failed(message: message))
            throw NSError(domain: "DreamNest.Audio", code: 404, userInfo: [NSLocalizedDescriptionKey: message])
        }

        print("[Audio] ✅ Resolved file URL: \(url.path)")

        let newPlayer: AVAudioPlayer
        do {
            newPlayer = try AVAudioPlayer(contentsOf: url)
        } catch {
            print("[Audio] ❌ AVAudioPlayer initialization failed: \(error.localizedDescription)")
            state.send(.failed(message: "Player initialization failed: \(error.localizedDescription)"))
            throw error
        }

        print("[Audio] ✅ AVAudioPlayer initialized for '\(sound.title)'")

        newPlayer.numberOfLoops = -1
        newPlayer.volume = 0
        newPlayer.prepareToPlay()

        guard newPlayer.play() else {
            let message = "AVAudioPlayer.play() returned false for file: \(url.lastPathComponent)"
            print("[Audio] ❌ \(message)")
            state.send(.failed(message: message))
            throw NSError(domain: "DreamNest.Audio", code: 500, userInfo: [NSLocalizedDescriptionKey: message])
        }

        let oldPlayer = player
        player = newPlayer
        nowPlayingSound = sound
        state.send(.playing(soundID: sound.id))
        updateNowPlaying(sound: sound, isPlaying: true)
        print("[Audio] ✅ Playback started for '\(sound.title)' with looping enabled")

        await crossfade(from: oldPlayer, to: newPlayer, targetVolume: max(0, min(volume, 1)))
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

    public func pause() {
        player?.pause()
        state.send(.idle)
        updateNowPlayingPlaybackState(isPlaying: false)
        print("[Audio] ℹ️ Playback paused")
    }

    public func resume() {
        guard let player else { return }
        guard player.play() else {
            print("[Audio] ❌ Resume failed: AVAudioPlayer.play() returned false")
            return
        }

        if let id = nowPlayingSound?.id {
            state.send(.playing(soundID: id))
        }
        updateNowPlayingPlaybackState(isPlaying: true)
        print("[Audio] ✅ Playback resumed")
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
        updateNowPlayingPlaybackState(isPlaying: false)
        print("[Audio] ✅ Playback stopped")
    }

    private func resolveBundledSoundURL(filename: String) -> URL? {
        let fileBase = (filename as NSString).deletingPathExtension
        let explicitExtension = (filename as NSString).pathExtension

        let candidateExts: [String]
        if explicitExtension.isEmpty {
            candidateExts = ["mp3", "wav", "m4a"]
        } else {
            candidateExts = [explicitExtension]
        }

        let subdirectories = [nil, "Audio", "Resources/Audio"]
        for ext in candidateExts {
            for subdirectory in subdirectories {
                if let url = Bundle.main.url(forResource: fileBase, withExtension: ext, subdirectory: subdirectory) {
                    return url
                }
            }
        }

        print("[Audio] ❌ Could not resolve bundled file for '\(filename)'. Tried extensions=\(candidateExts), subdirectories=\(subdirectories.map { $0 ?? "<root>" })")
        return nil
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
            updateNowPlayingPlaybackState(isPlaying: false)
        case .ended:
            player?.play()
            if let id = nowPlayingSound?.id { state.send(.playing(soundID: id)) }
            updateNowPlayingPlaybackState(isPlaying: true)
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

    private func updateNowPlaying(sound: SoundDefinition, isPlaying: Bool) {
        MPNowPlayingInfoCenter.default().nowPlayingInfo = [
            MPMediaItemPropertyTitle: sound.title,
            MPNowPlayingInfoPropertyIsLiveStream: false,
            MPNowPlayingInfoPropertyPlaybackRate: isPlaying ? 1 : 0
        ]
    }

    private func updateNowPlayingPlaybackState(isPlaying: Bool) {
        var info = MPNowPlayingInfoCenter.default().nowPlayingInfo ?? [:]
        info[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? 1 : 0
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }

    private func configureRemoteCommands() {
        let commandCenter = MPRemoteCommandCenter.shared()
        commandCenter.playCommand.isEnabled = true
        commandCenter.pauseCommand.isEnabled = true
        commandCenter.nextTrackCommand.isEnabled = false
        commandCenter.previousTrackCommand.isEnabled = false

        commandCenter.playCommand.addTarget { [weak self] _ in
            self?.resume()
            return .success
        }
        commandCenter.pauseCommand.addTarget { [weak self] _ in
            self?.pause()
            return .success
        }
    }
}
