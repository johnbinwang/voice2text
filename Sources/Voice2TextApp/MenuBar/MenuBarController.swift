import Cocoa
import SwiftUI

@MainActor
class MenuBarController {
    private var statusItem: NSStatusItem?
    private var settingsWindowController: NSWindowController?

    init() {
        setupMenuBar()
    }

    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "mic.fill", accessibilityDescription: "Voice2Text")
        }

        updateMenu()
    }

    private func updateMenu() {
        let menu = NSMenu()

        // Language submenu
        let languageMenu = NSMenu()
        for (code, name) in Constants.supportedLanguages {
            let item = NSMenuItem(title: name, action: #selector(selectLanguage(_:)), keyEquivalent: "")
            item.representedObject = code
            item.target = self
            item.state = AppSettings.shared.selectedLanguage == code ? .on : .off
            languageMenu.addItem(item)
        }

        let languageItem = NSMenuItem(title: "Language", action: nil, keyEquivalent: "")
        languageItem.submenu = languageMenu
        menu.addItem(languageItem)

        menu.addItem(NSMenuItem.separator())

        // LLM Refinement submenu
        let llmMenu = NSMenu()

        let enabledItem = NSMenuItem(title: "Enabled", action: #selector(toggleLLM(_:)), keyEquivalent: "")
        enabledItem.target = self
        enabledItem.state = AppSettings.shared.llmEnabled ? .on : .off
        llmMenu.addItem(enabledItem)

        llmMenu.addItem(NSMenuItem.separator())

        let settingsItem = NSMenuItem(title: "Settings...", action: #selector(openLLMSettings(_:)), keyEquivalent: "")
        settingsItem.target = self
        llmMenu.addItem(settingsItem)

        let llmItem = NSMenuItem(title: "LLM Refinement", action: nil, keyEquivalent: "")
        llmItem.submenu = llmMenu
        menu.addItem(llmItem)

        menu.addItem(NSMenuItem.separator())

        let debugLoggingItem = NSMenuItem(title: "Debug Logging", action: #selector(toggleDebugLogging(_:)), keyEquivalent: "")
        debugLoggingItem.target = self
        debugLoggingItem.state = AppSettings.shared.debugLoggingEnabled ? .on : .off
        menu.addItem(debugLoggingItem)

        let revealLogsItem = NSMenuItem(title: "Reveal Debug Log", action: #selector(revealDebugLog(_:)), keyEquivalent: "")
        revealLogsItem.target = self
        menu.addItem(revealLogsItem)

        menu.addItem(NSMenuItem.separator())

        // Quit
        let quitItem = NSMenuItem(title: "Quit", action: #selector(quit(_:)), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem?.menu = menu
    }

    @objc private func selectLanguage(_ sender: NSMenuItem) {
        guard let code = sender.representedObject as? String else { return }
        AppSettings.shared.selectedLanguage = code
        updateMenu()
    }

    @objc private func toggleLLM(_ sender: NSMenuItem) {
        AppSettings.shared.llmEnabled.toggle()
        updateMenu()
    }

    @objc private func toggleDebugLogging(_ sender: NSMenuItem) {
        AppSettings.shared.debugLoggingEnabled.toggle()
        Task {
            await DebugLogger.shared.log("debug_logging=\(AppSettings.shared.debugLoggingEnabled)")
        }
        updateMenu()
    }

    @objc private func revealDebugLog(_ sender: NSMenuItem) {
        Task {
            do {
                let path = try await DebugLogger.shared.logFilePath()
                await MainActor.run {
                    NSWorkspace.shared.activateFileViewerSelecting([URL(fileURLWithPath: path)])
                }
            } catch {
                await DebugLogger.shared.log("reveal_debug_log_failed error=\(error.localizedDescription)")
            }
        }
    }

    @objc private func openLLMSettings(_ sender: NSMenuItem) {
        if settingsWindowController == nil {
            let settingsView = SettingsView()
            let hostingController = NSHostingController(rootView: settingsView)
            let window = NSWindow(contentViewController: hostingController)
            window.title = "LLM Settings"
            window.styleMask = [.titled, .closable]
            window.setContentSize(NSSize(width: 500, height: 300))
            window.center()

            settingsWindowController = NSWindowController(window: window)
        }

        settingsWindowController?.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc private func quit(_ sender: NSMenuItem) {
        NSApplication.shared.terminate(nil)
    }
}
