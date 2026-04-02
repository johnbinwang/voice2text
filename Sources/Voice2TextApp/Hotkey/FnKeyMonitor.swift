import Cocoa
import Carbon

@MainActor
class FnKeyMonitor {
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var isFnPressed = false
    private var isAltPressed = false
    private var isEnabled = true

    var onFnPressed: (() -> Void)?
    var onFnReleased: (() -> Void)?

    func setEnabled(_ enabled: Bool) {
        isEnabled = enabled

        if !enabled {
            isFnPressed = false
            isAltPressed = false
        }
    }

    func start() {
        let eventMask = (1 << CGEventType.flagsChanged.rawValue) | (1 << CGEventType.keyDown.rawValue) | (1 << CGEventType.keyUp.rawValue)

        guard let eventTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(eventMask),
            callback: { (proxy, type, event, refcon) -> Unmanaged<CGEvent>? in
                guard let refcon = refcon else { return Unmanaged.passUnretained(event) }
                let monitor = Unmanaged<FnKeyMonitor>.fromOpaque(refcon).takeUnretainedValue()
                return monitor.handleEvent(proxy: proxy, type: type, event: event)
            },
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        ) else {
            print("Failed to create event tap")
            return
        }

        self.eventTap = eventTap
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: eventTap, enable: true)
    }

    func stop() {
        if let eventTap = eventTap {
            CGEvent.tapEnable(tap: eventTap, enable: false)
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        }
        eventTap = nil
        runLoopSource = nil
    }

    private func handleEvent(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            if let eventTap {
                CGEvent.tapEnable(tap: eventTap, enable: true)
            }
            return Unmanaged.passUnretained(event)
        }

        // Skip processing if monitoring is disabled
        guard isEnabled else {
            return Unmanaged.passUnretained(event)
        }

        if type == .flagsChanged {
            let flags = event.flags
            let fnPressed = flags.contains(.maskSecondaryFn)
            let altPressed = flags.contains(.maskAlternate)

            // Handle Fn key (Mac built-in keyboard)
            if fnPressed && !isFnPressed {
                isFnPressed = true
                Task { @MainActor in
                    self.onFnPressed?()
                }
                return nil
            } else if !fnPressed && isFnPressed {
                isFnPressed = false
                Task { @MainActor in
                    self.onFnReleased?()
                }
                return nil
            }

            // Handle Alt/Option key (external keyboard)
            if !isFnPressed {
                if altPressed && !isAltPressed {
                    isAltPressed = true
                    Task { @MainActor in
                        self.onFnPressed?()
                    }
                    return nil
                } else if !altPressed && isAltPressed {
                    isAltPressed = false
                    Task { @MainActor in
                        self.onFnReleased?()
                    }
                    return nil
                }
            }

            if !fnPressed {
                isFnPressed = false
            }

            if !altPressed {
                isAltPressed = false
            }
        }

        // Suppress Alt key events when we're using it as hotkey
        if type == .keyDown || type == .keyUp {
            if isAltPressed {
                return nil
            }
        }

        return Unmanaged.passUnretained(event)
    }
}
