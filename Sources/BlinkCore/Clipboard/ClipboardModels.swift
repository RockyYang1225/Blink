import Foundation

public struct NormalizedClipboardItem: Equatable, Sendable {
    public let contentType: ClipboardItemRecord.ContentType
    public let previewText: String
    public let searchableText: String
    public let sizeBytes: Int64
    public let cachePath: String?
    public let originalFileURL: URL?

    public init(
        contentType: ClipboardItemRecord.ContentType,
        previewText: String,
        searchableText: String,
        sizeBytes: Int64,
        cachePath: String? = nil,
        originalFileURL: URL? = nil
    ) {
        self.contentType = contentType
        self.previewText = previewText
        self.searchableText = searchableText
        self.sizeBytes = sizeBytes
        self.cachePath = cachePath
        self.originalFileURL = originalFileURL
    }
}

public protocol ClipboardWriting: Sendable {
    func writeText(_ text: String) async -> Bool
}

public struct NoopClipboardWriter: ClipboardWriting {
    public init() {}

    public func writeText(_ text: String) async -> Bool {
        true
    }
}

#if canImport(AppKit)
import AppKit

public struct SystemClipboardWriter: ClipboardWriting {
    public init() {}

    public func writeText(_ text: String) async -> Bool {
        await MainActor.run {
            let pasteboard = NSPasteboard.general
            pasteboard.clearContents()
            return pasteboard.setString(text, forType: .string)
        }
    }
}
#endif
