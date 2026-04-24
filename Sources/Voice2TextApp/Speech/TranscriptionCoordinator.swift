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
        guard !isRecording, !isProcessing else {
            Task {
                await DebugLogger.shared.log("recording_start_skipped isRecording=\(isRecording) isProcessing=\(isProcessing)")
            }
            return
        }
        isRecording = true
        currentTranscription = ""
        let sessionID = UUID()
        activeSessionID = sessionID

        Task {
            await DebugLogger.shared.log("recording_started session=\(sessionID.uuidString)")
        }

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
            Task {
                await DebugLogger.shared.log("speech_partial_forwarded session=\(sessionID.uuidString) text=\(text)")
            }
        }

        speechRecognition.onFinalResult = { [weak self] text in
            guard let self, self.activeSessionID == sessionID else { return }
            self.currentTranscription = text
            Task {
                await DebugLogger.shared.log("speech_final_forwarded session=\(sessionID.uuidString) text=\(text)")
            }
        }

        speechRecognition.onError = { [weak self] error in
            guard let self, self.activeSessionID == sessionID else { return }
            print("Speech recognition error: \(error)")
            Task {
                await DebugLogger.shared.log("speech_error_forwarded session=\(sessionID.uuidString) error=\(error.localizedDescription)")
            }
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

        Task {
            await DebugLogger.shared.log("recording_stopped session=\(sessionID.uuidString)")
        }

        hudController.hide()

        audioCapture.stop()
        speechRecognition.stop()

        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 150_000_000)
            let transcriptionSnapshot = self.currentTranscription
            await DebugLogger.shared.log("recording_snapshot session=\(sessionID.uuidString) text=\(transcriptionSnapshot)")
            await self.processTranscription(originalTranscription: transcriptionSnapshot, sessionID: sessionID)
        }
    }

    private func processTranscription(originalTranscription: String, sessionID: UUID) async {
        defer {
            isProcessing = false
            Task {
                await DebugLogger.shared.log("process_end session=\(sessionID.uuidString)")
            }
        }

        guard activeSessionID == sessionID else {
            await DebugLogger.shared.log("process_aborted_stale_session session=\(sessionID.uuidString)")
            return
        }

        let trimmedOriginalTranscription = originalTranscription.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedOriginalTranscription.isEmpty else {
            await DebugLogger.shared.log("process_empty_transcription session=\(sessionID.uuidString)")
            return
        }

        await DebugLogger.shared.log("process_begin session=\(sessionID.uuidString) text=\(trimmedOriginalTranscription)")

        do {
            try await historyStore.save(originalTranscriptionText: trimmedOriginalTranscription)
            await DebugLogger.shared.log("history_saved session=\(sessionID.uuidString)")
        } catch {
            print("Failed to save transcription history: \(error)")
            await DebugLogger.shared.log("history_save_failed session=\(sessionID.uuidString) error=\(error.localizedDescription)")
        }

        var finalText = originalTranscription

        if AppSettings.shared.llmEnabled && AppSettings.shared.isLLMConfigured {
            do {
                finalText = try await llmService.refine(text: originalTranscription)
                await DebugLogger.shared.log("llm_refine_success session=\(sessionID.uuidString) text=\(finalText)")
            } catch {
                print("LLM refinement failed: \(error)")
                await DebugLogger.shared.log("llm_refine_failed session=\(sessionID.uuidString) error=\(error.localizedDescription)")
            }
        }

        await DebugLogger.shared.log("inject_begin session=\(sessionID.uuidString) text=\(finalText)")
        await textInjector.inject(text: finalText)
        await DebugLogger.shared.log("inject_end session=\(sessionID.uuidString)")
    }
}
