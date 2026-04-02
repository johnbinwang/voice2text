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
        let granted = await AppPermissions.shared.checkAllPermissions()

        if granted {
            permissionPollingTask?.cancel()
            permissionPollingTask = nil
            startCoordinatorIfNeeded()
            return
        }

        guard promptIfNeeded, !hasPromptedForPermissions else { return }
        hasPromptedForPermissions = true
        AppPermissions.shared.promptForMissingPermissions()
        startPermissionPolling()
    }

    @MainActor
    private func startCoordinatorIfNeeded() {
        guard !hasStartedCoordinator else { return }
        transcriptionCoordinator?.start()
        hasStartedCoordinator = true
    }

    private func startPermissionPolling() {
        permissionPollingTask?.cancel()
        permissionPollingTask = Task { @MainActor in
            while !Task.isCancelled && !hasStartedCoordinator {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                let granted = await AppPermissions.shared.checkAllPermissions()
                if granted {
                    startCoordinatorIfNeeded()
                    permissionPollingTask = nil
                    break
                }
            }
        }
    }
}
