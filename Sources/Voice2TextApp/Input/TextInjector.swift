import Cocoa

@MainActor
class TextInjector {
    private let inputSourceManager = InputSourceManager()

    func inject(text: String) async {
        guard !text.isEmpty else { return }

        await DebugLogger.shared.log("text_injector_start text=\(text)")

        // Save only plain text. Restoring full NSPasteboardItem objects can block on
        // promised data from other apps, which would freeze the main actor.
        let pasteboard = NSPasteboard.general
        let savedString = pasteboard.string(forType: .string)

        // Save current input source
        let currentInputSource = inputSourceManager.getCurrentInputSource()
        let needsInputSourceSwitch = currentInputSource.map { inputSourceManager.isCJKInputSource($0) } ?? false

        // Switch to ASCII input source if needed
        if needsInputSourceSwitch {
            await DebugLogger.shared.log("text_injector_switch_ascii")
            _ = inputSourceManager.switchToASCIIInputSource()
            try? await Task.sleep(nanoseconds: 100_000_000)
        }

        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)

        await DebugLogger.shared.log("text_injector_pasteboard_set")
        await simulatePaste()
        await DebugLogger.shared.log("text_injector_paste_sent")

        try? await Task.sleep(nanoseconds: 100_000_000)
        await DebugLogger.shared.log("text_injector_end")

        if needsInputSourceSwitch, let source = currentInputSource {
            await DebugLogger.shared.log("text_injector_restore_input_source_begin")
            inputSourceManager.switchToInputSource(source)
            await DebugLogger.shared.log("text_injector_restore_input_source_end")
        }

        await DebugLogger.shared.log("text_injector_restore_pasteboard_begin")
        pasteboard.clearContents()
        if let savedString {
            pasteboard.setString(savedString, forType: .string)
        }
        await DebugLogger.shared.log("text_injector_restore_pasteboard_end")
    }

    private func simulatePaste() async {
        let source = CGEventSource(stateID: .hidSystemState)

        // Cmd down
        let cmdDown = CGEvent(keyboardEventSource: source, virtualKey: 0x37, keyDown: true)
        cmdDown?.flags = .maskCommand

        // V down
        let vDown = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: true)
        vDown?.flags = .maskCommand

        // V up
        let vUp = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: false)
        vUp?.flags = .maskCommand

        // Cmd up
        let cmdUp = CGEvent(keyboardEventSource: source, virtualKey: 0x37, keyDown: false)

        let location = CGEventTapLocation.cghidEventTap

        cmdDown?.post(tap: location)
        try? await Task.sleep(nanoseconds: 10_000_000) // 10ms
        vDown?.post(tap: location)
        try? await Task.sleep(nanoseconds: 10_000_000) // 10ms
        vUp?.post(tap: location)
        try? await Task.sleep(nanoseconds: 10_000_000) // 10ms
        cmdUp?.post(tap: location)
    }
}
