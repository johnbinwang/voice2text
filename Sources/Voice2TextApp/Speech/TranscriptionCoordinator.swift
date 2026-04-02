import Foundation

@MainActor
class TranscriptionCoordinator {
    private let fnKeyMonitor = FnKeyMonitor()
    private let audioCapture = AudioCaptureService()
    private let speechRecognition = SpeechRecognitionService()
    private let hudController = RecordingHUDController()
    private let llmService = LLMRefinementService()
    private let textInjector = TextInjector()
    private let historyStore = TranscriptionHistoryStore.shared

    private var isRecording = false
    private var isProcessing = false
    private var currentTranscription = ""
    private var activeSessionID = UUID()

    func start() {
        fnKeyMonitor.onFnPressed = { [weak self] in
            self?.startRecording()
        }

        fnKeyMonitor.onFnReleased = { [weak self] in
            self?.stopRecording()
        }

        fnKeyMonitor.start()
    }

    func stop() {
        fnKeyMonitor.stop()
        if isRecording {
            stopRecording()
        }
    }

    private func startRecording() {
        guard !isRecording, !isProcessing else { return }
        isRecording = true
        currentTranscription = ""
        let sessionID = UUID()
        activeSessionID = sessionID

        hudController.updateText("Listening...")
        hudController.show()

        // Setup audio capture callbacks
        audioCapture.onAudioBuffer = { [weak self] buffer in
            self?.speechRecognition.append(buffer: buffer)
        }

        audioCapture.onRMSLevel = { [weak self] level in
            self?.hudController.updateRMS(level)
        }

        // Setup speech recognition callbacks
        speechRecognition.onPartialResult = { [weak self] text in
            guard let self, self.activeSessionID == sessionID else { return }
            self.currentTranscription = text
            self.hudController.updateText(text.isEmpty ? "Listening..." : text)
        }

        speechRecognition.onFinalResult = { [weak self] text in
            guard let self, self.activeSessionID == sessionID else { return }
            self.currentTranscription = text
        }

        speechRecognition.onError = { [weak self] error in
            guard let self, self.activeSessionID == sessionID else { return }
            print("Speech recognition error: \(error)")
        }

        do {
            try audioCapture.start()
            try speechRecognition.start(language: AppSettings.shared.selectedLanguage)
        } catch {
            print("Failed to start recording: \(error)")
            isRecording = false
            hudController.hide()
        }
    }

    private func stopRecording() {
        guard isRecording else { return }
        isRecording = false
        isProcessing = true
        let sessionID = activeSessionID

        hudController.hide()

        audioCapture.stop()
        speechRecognition.stop()

        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 150_000_000)
            let transcriptionSnapshot = self.currentTranscription
            await self.processTranscription(originalTranscription: transcriptionSnapshot, sessionID: sessionID)
        }
    }

    private func processTranscription(originalTranscription: String, sessionID: UUID) async {
        defer {
            if activeSessionID == sessionID {
                isProcessing = false
            }
        }

        guard activeSessionID == sessionID else { return }

        let trimmedOriginalTranscription = originalTranscription.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedOriginalTranscription.isEmpty else {
            return
        }

        do {
            try await historyStore.save(originalTranscriptionText: trimmedOriginalTranscription)
        } catch {
            print("Failed to save transcription history: \(error)")
        }

        var finalText = originalTranscription

        if AppSettings.shared.llmEnabled && AppSettings.shared.isLLMConfigured {
            do {
                finalText = try await llmService.refine(text: originalTranscription)
            } catch {
                print("LLM refinement failed: \(error)")
            }
        }

        fnKeyMonitor.setEnabled(false)
        defer {
            fnKeyMonitor.setEnabled(true)
            fnKeyMonitor.stop()
            fnKeyMonitor.start()
        }
        await textInjector.inject(text: finalText)
    }
}
