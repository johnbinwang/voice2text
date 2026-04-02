import Carbon
import Cocoa

@MainActor
class InputSourceManager {
    func getCurrentInputSource() -> TISInputSource? {
        return TISCopyCurrentKeyboardInputSource()?.takeRetainedValue()
    }

    func getInputSourceID(_ source: TISInputSource) -> String? {
        let ptr = TISGetInputSourceProperty(source, kTISPropertyInputSourceID)
        return Unmanaged<CFString>.fromOpaque(ptr!).takeUnretainedValue() as String
    }

    func isCJKInputSource(_ source: TISInputSource) -> Bool {
        guard let sourceID = getInputSourceID(source) else { return false }
        let cjkPrefixes = ["com.apple.inputmethod.SCIM", "com.apple.inputmethod.TCIM",
                          "com.apple.inputmethod.Korean", "com.apple.inputmethod.Japanese"]
        return cjkPrefixes.contains { sourceID.hasPrefix($0) }
    }

    func switchToASCIIInputSource() -> TISInputSource? {
        let inputSourceNSArray = TISCreateInputSourceList(nil, false).takeRetainedValue() as NSArray
        let inputSourceList = inputSourceNSArray as! [TISInputSource]

        for source in inputSourceList {
            guard let sourceID = getInputSourceID(source) else { continue }

            // Prefer ABC or US keyboard
            if sourceID == "com.apple.keylayout.ABC" || sourceID == "com.apple.keylayout.US" {
                TISSelectInputSource(source)
                return source
            }
        }

        // Fallback: find any ASCII-capable source
        for source in inputSourceList {
            let ptr = TISGetInputSourceProperty(source, kTISPropertyInputSourceIsASCIICapable)
            if ptr != nil {
                let isASCII = Unmanaged<CFBoolean>.fromOpaque(ptr!).takeUnretainedValue()
                if CFBooleanGetValue(isASCII) {
                    TISSelectInputSource(source)
                    return source
                }
            }
        }

        return nil
    }

    func switchToInputSource(_ source: TISInputSource) {
        TISSelectInputSource(source)
    }
}
