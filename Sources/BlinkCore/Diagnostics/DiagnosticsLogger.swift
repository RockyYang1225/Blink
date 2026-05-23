import Foundation

public struct DiagnosticsLogger: Sendable {
    public let logURL: URL

    public init(logURL: URL) {
        self.logURL = logURL
    }

    public func append(_ message: String) throws {
        try FileManager.default.createDirectory(
            at: logURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )

        let timestamp = ISO8601DateFormatter().string(from: Date())
        let line = "\(timestamp) \(message)\n"

        if FileManager.default.fileExists(atPath: logURL.path) {
            let handle = try FileHandle(forWritingTo: logURL)
            try handle.seekToEnd()
            try handle.write(contentsOf: Data(line.utf8))
            try handle.close()
        } else {
            try line.write(to: logURL, atomically: true, encoding: .utf8)
        }
    }
}
