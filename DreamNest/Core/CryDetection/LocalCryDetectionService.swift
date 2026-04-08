import AVFoundation
import Combine
import Foundation
import Accelerate

public final class LocalCryDetectionService: CryDetectionControlling {
    private let engine = AVAudioEngine()
    private let stateMachine: CryDetectionStateMachine
    private let subject = PassthroughSubject<CryDetectionSignal, Never>()

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
        let input = engine.inputNode
        let format = input.outputFormat(forBus: 0)

        input.installTap(onBus: 0, bufferSize: 2048, format: format) { [weak self] buffer, _ in
            guard let self,
                  let frame = self.extractFeatures(from: buffer, sampleRate: Float(format.sampleRate))
            else { return }

            let signal = self.stateMachine.process(frame)
            if signal.detected { self.subject.send(signal) }
        }

        engine.prepare()
        try engine.start()
    }

    public func stop() {
        engine.inputNode.removeTap(onBus: 0)
        engine.stop()
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
