import Foundation

public struct AppPaths: Sendable {
    public let applicationSupportDirectory: URL
    public let cacheDirectory: URL
    public let logsDirectory: URL

    public init(applicationSupportDirectory: URL) {
        self.applicationSupportDirectory = applicationSupportDirectory
        self.cacheDirectory = applicationSupportDirectory.appendingPathComponent("ClipboardCache", isDirectory: true)
        self.logsDirectory = applicationSupportDirectory.appendingPathComponent("Logs", isDirectory: true)
    }

    public static func live(fileManager: FileManager = .default) throws -> AppPaths {
        let base = try fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        ).appendingPathComponent("Blink", isDirectory: true)

        try fileManager.createDirectory(at: base, withIntermediateDirectories: true)
        try fileManager.createDirectory(at: base.appendingPathComponent("ClipboardCache", isDirectory: true), withIntermediateDirectories: true)
        try fileManager.createDirectory(at: base.appendingPathComponent("Logs", isDirectory: true), withIntermediateDirectories: true)

        return AppPaths(applicationSupportDirectory: base)
    }

    public var databaseURL: URL {
        applicationSupportDirectory.appendingPathComponent("Blink.sqlite")
    }

    public var settingsURL: URL {
        applicationSupportDirectory.appendingPathComponent("settings.json")
    }

    public var logURL: URL {
        logsDirectory.appendingPathComponent("blink.log")
    }
}
