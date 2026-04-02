import Cocoa
import SwiftUI

@MainActor
class RecordingHUDController: ObservableObject {
    private var panel: NSPanel?
    private var hostingView: NSHostingView<RecordingHUDView>?

    @Published var rmsLevel: Float = 0.0
    @Published var text: String = "Listening..."

    func show() {
        if panel == nil {
            createPanel()
        }

        guard let panel = panel else { return }

        // Position at bottom center
        if let screen = NSScreen.main {
            let screenFrame = screen.visibleFrame
            let panelWidth = calculateWidth()
            let panelHeight = Constants.hudHeight
            let x = screenFrame.midX - panelWidth / 2
            let y = screenFrame.minY + 100

            panel.setFrame(NSRect(x: x, y: y, width: panelWidth, height: panelHeight), display: false)
        }

        // Entrance animation
        panel.alphaValue = 0
        panel.setIsVisible(true)
        panel.orderFrontRegardless()

        NSAnimationContext.runAnimationGroup { context in
            context.duration = Constants.hudEntranceAnimationDuration
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            panel.animator().alphaValue = 1.0
        }
    }

    func hide() {
        guard let panel = panel else {
            return
        }

        // Exit animation
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = Constants.hudExitAnimationDuration
            context.timingFunction = CAMediaTimingFunction(name: .easeIn)
            panel.animator().alphaValue = 0
        }, completionHandler: {
            panel.setIsVisible(false)
        })
    }

    func updateRMS(_ level: Float) {
        rmsLevel = level
        updateWidth()
    }

    func updateText(_ newText: String) {
        text = newText
        updateWidth()
    }

    private func createPanel() {
        let contentView = RecordingHUDView(rmsLevel: rmsLevel, text: text)
        hostingView = NSHostingView(rootView: contentView)

        panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: Constants.hudMinWidth, height: Constants.hudHeight),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        panel?.isOpaque = false
        panel?.backgroundColor = .clear
        panel?.level = .floating
        panel?.collectionBehavior = [.canJoinAllSpaces, .stationary]
        panel?.contentView = hostingView
    }

    private func calculateWidth() -> CGFloat {
        let textWidth = (text as NSString).size(withAttributes: [
            .font: NSFont.systemFont(ofSize: 14, weight: .medium)
        ]).width

        let totalWidth = 40 + Constants.waveformWidth + 16 + textWidth + 40
        return min(max(totalWidth, Constants.hudMinWidth), Constants.hudMaxWidth)
    }

    private func updateWidth() {
        guard let panel = panel, panel.isVisible else { return }

        let newWidth = calculateWidth()
        var frame = panel.frame
        let oldWidth = frame.width
        frame.size.width = newWidth
        frame.origin.x += (oldWidth - newWidth) / 2

        NSAnimationContext.runAnimationGroup { context in
            context.duration = Constants.hudWidthAnimationDuration
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            panel.animator().setFrame(frame, display: true)
        }

        // Update hosting view
        hostingView?.rootView = RecordingHUDView(rmsLevel: rmsLevel, text: text)
    }
}
