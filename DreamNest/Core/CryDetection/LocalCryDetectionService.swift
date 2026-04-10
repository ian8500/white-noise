import AVFoundation
import Combine
import Foundation
import Accelerate
import OSLog

public final class LocalCryDetectionService: CryDetectionControlling {
    private let logger = Logger(subsystem: "com.dreamnest.app", category: "CryDetection")
    private let engine = AVAudioEngine()
    private let stateMachine: CryDetectionStateMachine
    private let subject = PassthroughSubject<CryDetectionSignal, Never>()
    private var isRunning = false

    public var detectionPublisher: AnyPublisher<CryDetectionSignal, Never> { subject.eraseToAnyPublisher() }

    public init(stateMachine: CryDetectionStateMachine = .init()) {
        self.stateMachine = stateMachine
    }

    public func requestPermission() async -> Bool {
        await withCheckedContinuation { continuation in
            AVAudioApplication.requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }
    }

    public func start() throws {
        guard !isRunning else { return }
        let input = engine.inputNode
        let inputFormat = input.inputFormat(forBus: 0)
        let outputFormat = input.outputFormat(forBus: 0)
        let sampleRate = outputFormat.sampleRate > 0 ? outputFormat.sampleRate : inputFormat.sampleRate

        guard sampleRate > 0 else {
            throw NSError(
                domain: "DreamNest.CryDetection",
                code: 1001,
                userInfo: [NSLocalizedDescriptionKey: "Microphone is unavailable right now. Try reconnecting audio devices and starting cry detection again."]
            )
        }

        if outputFormat.channelCount == 0 {
            throw NSError(
                domain: "DreamNest.CryDetection",
                code: 1002,
                userInfo: [NSLocalizedDescriptionKey: "No microphone input channels were detected."]
            )
        }

        logger.info("Starting cry detection. input=\(inputFormat.description, privacy: .public), output=\(outputFormat.description, privacy: .public)")

        input.removeTap(onBus: 0)
        engine.stop()
        engine.reset()

        input.installTap(onBus: 0, bufferSize: 2048, format: nil) { [weak self] buffer, _ in
            guard let self,
                  let frame = self.extractFeatures(from: buffer, sampleRate: Float(sampleRate))
            else { return }

            let signal = self.stateMachine.process(frame)
            if signal.detected { self.subject.send(signal) }
        }

        engine.prepare()
        try engine.start()
        isRunning = true
    }

    public func stop() {
        guard isRunning else { return }
        engine.inputNode.removeTap(onBus: 0)
        engine.stop()
        engine.reset()
        isRunning = false
    }

    public func updateDetectionThreshold(_ threshold: Float) {
        stateMachine.updateDetectionThreshold(threshold)
    }

    public func updateCooldown(_ cooldown: TimeInterval) {
        stateMachine.updateCooldown(cooldown)
    }

    private func extractFeatures(from buffer: AVAudioPCMBuffer, sampleRate: Float) -> CryHeuristicFrame? {
        guard let samples = buffer.floatChannelData?[0] else { return nil }
        let count = Int(buffer.frameLength)
        guard count > 2 else { return nil }

        var rms: Float = 0
        vDSP_rmsqv(samples, 1, &rms, vDSP_Length(count))

        var crossings = 0
        var highEnergy: Float = 0
        var lowEnergy: Float = 0

        for i in 1 ..< count {
            let current = samples[i]
            let previous = samples[i - 1]
            if (current >= 0 && previous < 0) || (current < 0 && previous >= 0) { crossings += 1 }

            let diff = current - previous
            highEnergy += diff * diff
            lowEnergy += current * current
        }

        let duration = Float(count) / sampleRate
        let zeroCrossingRate = Float(crossings) / max(duration, 0.001)
        let centroidProxy = zeroCrossingRate * 0.5
        let bandRatio = highEnergy / max(1e-5, lowEnergy)

        return CryHeuristicFrame(rms: rms, centroid: centroidProxy, bandEnergyRatio: bandRatio)
    }
}
