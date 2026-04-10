import AVFoundation
import Combine
import Foundation
import MediaPlayer
import UIKit

@MainActor
public final class SystemVolumeService: NSObject, SystemVolumeControlling {
    private let volumeSubject: CurrentValueSubject<Float, Never>
    private weak var volumeSlider: UISlider?

    public var volumePublisher: AnyPublisher<Float, Never> { volumeSubject.eraseToAnyPublisher() }
    public var currentVolume: Float { volumeSubject.value }

    public override init() {
        let initialVolume = AVAudioSession.sharedInstance().outputVolume
        volumeSubject = CurrentValueSubject(initialVolume)
        super.init()

        configureVolumeSlider()
        AVAudioSession.sharedInstance().addObserver(self, forKeyPath: #keyPath(AVAudioSession.outputVolume), options: [.new, .initial], context: nil)
    }

    deinit {
        AVAudioSession.sharedInstance().removeObserver(self, forKeyPath: #keyPath(AVAudioSession.outputVolume))
    }

    public func setSystemVolume(_ value: Float) {
        let clamped = max(0, min(1, value))
        volumeSubject.send(clamped)

        if volumeSlider == nil {
            configureVolumeSlider()
        }
        volumeSlider?.setValue(clamped, animated: false)
        volumeSlider?.sendActions(for: .touchUpInside)
    }

    public override func observeValue(
        forKeyPath keyPath: String?,
        of object: Any?,
        change: [NSKeyValueChangeKey: Any]?,
        context: UnsafeMutableRawPointer?
    ) {
        guard keyPath == #keyPath(AVAudioSession.outputVolume) else { return }
        let updatedVolume = AVAudioSession.sharedInstance().outputVolume
        volumeSubject.send(updatedVolume)
    }

    private func configureVolumeSlider() {
        let volumeView = MPVolumeView(frame: .zero)
        volumeView.alpha = 0.0001
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first(where: \.isKeyWindow)?
            .addSubview(volumeView)

        volumeSlider = volumeView.subviews.compactMap { $0 as? UISlider }.first
    }
}
