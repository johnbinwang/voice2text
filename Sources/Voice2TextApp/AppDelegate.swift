import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {
    private var menuBarController: MenuBarController?
    private var transcriptionCoordinator: TranscriptionCoordinator?
    private var hasStartedCoordinator = false
    private var hasPromptedForPermissions = false
    private var permissionPollingTask: Task<Void, Never>?

    func applicationDidFinishLaunching(_ notification: Notification) {
        _ = AppSettings.shared

        menuBarController = MenuBarController()
        transcriptionCoordinator = TranscriptionCoordinator()

        Task { @MainActor in
            await evaluatePermissionsAndStart(promptIfNeeded: true)
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        permissionPollingTask?.cancel()
        transcriptionCoordinator?.stop()
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }

    @MainActor
    private func evaluatePermissionsAndStart(promptIfNeeded: Bool) async {
        await DebugLogger.shared.log("permissions_check prompt=\(promptIfNeeded)")
        let status = await AppPermissions.shared.currentPermissionStatus()
        await DebugLogger.shared.log("permissions_result microphone=\(status.microphoneGranted) speech=\(status.speechGranted) accessibility=\(status.accessibilityGranted) granted=\(status.allGranted)")

        if status.allGranted {
            permissionPollingTask?.cancel()
            permissionPollingTask = nil
            startCoordinatorIfNeeded()
            return
        }

        guard promptIfNeeded, !hasPromptedForPermissions else { return }
        hasPromptedForPermissions = true
        await DebugLogger.shared.log("permissions_prompt_shown")
        AppPermissions.shared.promptForMissingPermissions()
        startPermissionPolling()
    }

    @MainActor
    private func startCoordinatorIfNeeded() {
        guard !hasStartedCoordinator else { return }
        transcriptionCoordinator?.start()
        hasStartedCoordinator = true
        Task {
            await DebugLogger.shared.log("transcription_coordinator_started")
        }
    }

    private func startPermissionPolling() {
        permissionPollingTask?.cancel()
        permissionPollingTask = Task { @MainActor in
            await DebugLogger.shared.log("permissions_polling_started")
            while !Task.isCancelled && !hasStartedCoordinator {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                let status = await AppPermissions.shared.currentPermissionStatus()
                await DebugLogger.shared.log("permissions_poll microphone=\(status.microphoneGranted) speech=\(status.speechGranted) accessibility=\(status.accessibilityGranted) granted=\(status.allGranted)")
                if status.allGranted {
                    startCoordinatorIfNeeded()
                    permissionPollingTask = nil
                    await DebugLogger.shared.log("permissions_polling_completed")
                    break
                }
            }
        }
    }
}
