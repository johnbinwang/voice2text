import Foundation

actor TranscriptionHistoryStore {
    static let shared = TranscriptionHistoryStore()

    private let encoder: JSONEncoder
    private let fileManager: FileManager

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
        self.encoder = JSONEncoder()
        self.encoder.dateEncodingStrategy = .iso8601
    }

    func save(originalTranscriptionText text: String) async throws {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else { return }

        let fileURL = try historyFileURL()
        try ensureParentDirectoryExists(for: fileURL)

        let record = TranscriptionRecord(text: trimmedText)
        let data = try encoder.encode(record)
        var line = Data()
        line.append(data)
        line.append(Data("\n".utf8))

        if fileManager.fileExists(atPath: fileURL.path) {
            let handle = try FileHandle(forWritingTo: fileURL)
            defer {
                try? handle.close()
            }
            try handle.seekToEnd()
            try handle.write(contentsOf: line)
        } else {
            try line.write(to: fileURL, options: .atomic)
        }
    }

    func historyFilePath() throws -> String {
        try historyFileURL().path
    }

    private func historyFileURL() throws -> URL {
        let appSupportURL = try fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )

        return appSupportURL
            .appendingPathComponent(Constants.appSupportDirectoryName, isDirectory: true)
            .appendingPathComponent(Constants.transcriptionHistoryFileName, isDirectory: false)
    }

    private func ensureParentDirectoryExists(for fileURL: URL) throws {
        let directoryURL = fileURL.deletingLastPathComponent()
        try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)
    }
}
