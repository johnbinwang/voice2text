import Cocoa
import Speech
import AVFoundation

@MainActor
class AppPermissions {
    static let shared = AppPermissions()

    struct PermissionStatus {
        let microphoneGranted: Bool
        let speechGranted: Bool
        let accessibilityGranted: Bool

        var allGranted: Bool {
            microphoneGranted && speechGranted && accessibilityGranted
        }
    }

    private init() {}

    func currentPermissionStatus() async -> PermissionStatus {
        let microphoneGranted = await checkMicrophonePermission()
        let speechGranted = await checkSpeechRecognitionPermission()
        let accessibilityGranted = checkAccessibilityPermission(prompt: false)

        return PermissionStatus(
            microphoneGranted: microphoneGranted,
            speechGranted: speechGranted,
            accessibilityGranted: accessibilityGranted
        )
    }

    func checkAllPermissions() async -> Bool {
        await currentPermissionStatus().allGranted
    }

    func checkMicrophonePermission() async -> Bool {
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .authorized:
            return true
        case .notDetermined:
            return await AVCaptureDevice.requestAccess(for: .audio)
        default:
            return false
        }
    }

    func checkSpeechRecognitionPermission() async -> Bool {
        let status = SFSpeechRecognizer.authorizationStatus()
        switch status {
        case .authorized:
            return true
        case .notDetermined:
            return await withCheckedContinuation { continuation in
                SFSpeechRecognizer.requestAuthorization { newStatus in
                    continuation.resume(returning: newStatus == .authorized)
                }
            }
        default:
            return false
        }
    }

    func checkAccessibilityPermission(prompt: Bool) -> Bool {
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: prompt]
        return AXIsProcessTrustedWithOptions(options)
    }

    func promptForMissingPermissions() {
        _ = checkAccessibilityPermission(prompt: true)

        let alert = NSAlert()
        alert.messageText = "Permissions Required"
        alert.informativeText = """
        Voice2Text needs the following permissions to work:

        • Microphone access (for recording)
        • Speech recognition (for transcription)
        • Accessibility access (for text injection)

        After granting permissions, return to Voice2Text and it will activate automatically.
        If macOS still does not activate the permissions immediately, reopen the app once.
        """
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Open System Settings")
        alert.addButton(withTitle: "Later")

        if alert.runModal() == .alertFirstButtonReturn {
            NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy")!)
        }
    }
}
