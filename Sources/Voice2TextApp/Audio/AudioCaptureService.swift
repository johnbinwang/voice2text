import AVFoundation
import Accelerate

@MainActor
class AudioCaptureService {
    private var audioEngine: AVAudioEngine?
    private var inputNode: AVAudioInputNode?

    var onAudioBuffer: ((AVAudioPCMBuffer) -> Void)?
    var onRMSLevel: ((Float) -> Void)?

    private var smoothedRMS: Float = 0.0

    func start() throws {
        audioEngine = AVAudioEngine()
        inputNode = audioEngine?.inputNode

        guard let inputNode = inputNode else {
            throw AudioError.noInputNode
        }

        let recordingFormat = inputNode.outputFormat(forBus: 0)

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            Task { @MainActor in
                // Send buffer for speech recognition
                self?.onAudioBuffer?(buffer)

                // Calculate RMS for waveform
                if let rms = self?.calculateRMS(buffer: buffer) {
                    self?.updateSmoothedRMS(rms)
                }
            }
        }

        audioEngine?.prepare()
        try audioEngine?.start()
    }

    func stop() {
        inputNode?.removeTap(onBus: 0)
        audioEngine?.stop()
        audioEngine = nil
        inputNode = nil
        smoothedRMS = 0.0
    }

    private func calculateRMS(buffer: AVAudioPCMBuffer) -> Float {
        guard let channelData = buffer.floatChannelData else { return 0.0 }

        let channelDataValue = channelData.pointee
        let channelDataValueArray = stride(from: 0, to: Int(buffer.frameLength), by: buffer.stride).map { channelDataValue[$0] }

        let rms = sqrt(channelDataValueArray.map { $0 * $0 }.reduce(0, +) / Float(buffer.frameLength))

        // Convert to dB and normalize to 0...1 range
        let db = 20 * log10(rms)
        let normalizedDB = (db + 50) / 50 // Assuming -50dB to 0dB range
        return max(0, min(1, normalizedDB))
    }

    private func updateSmoothedRMS(_ newRMS: Float) {
        // Apply attack/release envelope
        let attackRate = Float(Constants.waveformAttackRate)
        let releaseRate = Float(Constants.waveformReleaseRate)

        if newRMS > smoothedRMS {
            // Attack: rise quickly
            smoothedRMS += (newRMS - smoothedRMS) * attackRate
        } else {
            // Release: fall slowly
            smoothedRMS += (newRMS - smoothedRMS) * releaseRate
        }

        onRMSLevel?(smoothedRMS)
    }
}

enum AudioError: LocalizedError {
    case noInputNode

    var errorDescription: String? {
        switch self {
        case .noInputNode:
            return "No audio input node available"
        }
    }
}
