import Foundation

actor DebugLogger {
    static let shared = DebugLogger()

    private let fileManager = FileManager.default
    private let isoFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    func log(_ message: String) async {
        let isEnabled = await MainActor.run { AppSettings.shared.debugLoggingEnabled }
        guard isEnabled else { return }

        do {
            let fileURL = try logFileURL()
            try ensureParentDirectoryExists(for: fileURL)
            let line = "[\(isoFormatter.string(from: Date()))] \(message)\n"
            let data = Data(line.utf8)

            if fileManager.fileExists(atPath: fileURL.path) {
                let handle = try FileHandle(forWritingTo: fileURL)
                defer { try? handle.close() }
                try handle.seekToEnd()
                try handle.write(contentsOf: data)
            } else {
                try data.write(to: fileURL, options: .atomic)
            }
        } catch {
            print("Failed to write debug log: \(error)")
        }
    }

    func logFilePath() throws -> String {
        try logFileURL().path
    }

    private func logFileURL() throws -> URL {
        let appSupportURL = try fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )

        return appSupportURL
            .appendingPathComponent(Constants.appSupportDirectoryName, isDirectory: true)
            .appendingPathComponent(Constants.debugLogFileName, isDirectory: false)
    }

    private func ensureParentDirectoryExists(for fileURL: URL) throws {
        try fileManager.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
    }
}
