import Foundation

public struct BlinkSettings: Codable, Equatable, Sendable {
    public var hotkeyName: String
    public var clipboardRecordingEnabled: Bool
    public var maxItemCount: Int
    public var maxRetentionDays: Int
    public var maxCacheBytes: Int64
    public var excludedBundleIDs: [String]
    public var excludedContentTypes: [String]

    public init(
        hotkeyName: String,
        clipboardRecordingEnabled: Bool,
        maxItemCount: Int,
        maxRetentionDays: Int,
        maxCacheBytes: Int64,
        excludedBundleIDs: [String],
        excludedContentTypes: [String]
    ) {
        self.hotkeyName = hotkeyName
        self.clipboardRecordingEnabled = clipboardRecordingEnabled
        self.maxItemCount = maxItemCount
        self.maxRetentionDays = maxRetentionDays
        self.maxCacheBytes = maxCacheBytes
        self.excludedBundleIDs = excludedBundleIDs
        self.excludedContentTypes = excludedContentTypes
    }

    public static let defaults = BlinkSettings(
        hotkeyName: "Option-Space",
        clipboardRecordingEnabled: true,
        maxItemCount: 500,
        maxRetentionDays: 30,
        maxCacheBytes: 250_000_000,
        excludedBundleIDs: [],
        excludedContentTypes: []
    )
}

public struct SettingsStore: Sendable {
    public let url: URL

    public init(url: URL) {
        self.url = url
    }

    public func load() throws -> BlinkSettings {
        guard FileManager.default.fileExists(atPath: url.path) else {
            return .defaults
        }

        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(BlinkSettings.self, from: data)
    }

    public func save(_ settings: BlinkSettings) throws {
        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(settings)
        try data.write(to: url, options: .atomic)
    }
}
