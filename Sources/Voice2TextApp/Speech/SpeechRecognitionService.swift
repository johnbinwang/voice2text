import Speech

@MainActor
class SpeechRecognitionService {
    private var speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?

    var onPartialResult: ((String) -> Void)?
    var onFinalResult: ((String) -> Void)?
    var onError: ((Error) -> Void)?

    func start(language: String) throws {
        // Clean up any previous session first
        stop()

        let locale = Locale(identifier: language)
        speechRecognizer = SFSpeechRecognizer(locale: locale)

        guard let speechRecognizer = speechRecognizer, speechRecognizer.isAvailable else {
            throw SpeechError.recognizerNotAvailable
        }

        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            throw SpeechError.cannotCreateRequest
        }

        recognitionRequest.shouldReportPartialResults = true

        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            Task { @MainActor in
                if let error = error {
                    self?.onError?(error)
                    return
                }

                guard let result = result else { return }

                let transcription = result.bestTranscription.formattedString

                if result.isFinal {
                    self?.onFinalResult?(transcription)
                } else {
                    self?.onPartialResult?(transcription)
                }
            }
        }
    }

    func append(buffer: AVAudioPCMBuffer) {
        recognitionRequest?.append(buffer)
    }

    func stop() {
        recognitionRequest?.endAudio()
        recognitionTask?.finish()
        recognitionTask = nil
        recognitionRequest = nil
        speechRecognizer = nil
    }
}

enum SpeechError: LocalizedError {
    case recognizerNotAvailable
    case cannotCreateRequest

    var errorDescription: String? {
        switch self {
        case .recognizerNotAvailable:
            return "Speech recognizer is not available"
        case .cannotCreateRequest:
            return "Cannot create recognition request"
        }
    }
}
