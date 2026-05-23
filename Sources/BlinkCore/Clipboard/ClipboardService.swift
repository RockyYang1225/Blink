import Foundation

#if canImport(AppKit)
import AppKit

@MainActor
public final class ClipboardService {
    private let pasteboard: NSPasteboard
    private let repository: ClipboardRepository
    private var lastChangeCount: Int

    public init(pasteboard: NSPasteboard = .general, repository: ClipboardRepository) {
        self.pasteboard = pasteboard
        self.repository = repository
        self.lastChangeCount = pasteboard.changeCount
    }

    public func captureIfChanged() throws {
        guard pasteboard.changeCount != lastChangeCount else {
            return
        }

        lastChangeCount = pasteboard.changeCount

        if let text = pasteboard.string(forType: .string), !text.isEmpty {
            try repository.insert(record(for: .init(
                contentType: .text,
                previewText: preview(text),
                searchableText: text,
                sizeBytes: Int64(text.utf8.count)
            )))
            return
        }

        if let fileURLString = pasteboard.string(forType: .fileURL),
           let url = URL(string: fileURLString) {
            try repository.insert(record(for: .init(
                contentType: .file,
                previewText: url.lastPathComponent,
                searchableText: url.path,
                sizeBytes: 0,
                originalFileURL: url
            )))
            return
        }

        if let imageData = pasteboard.data(forType: .tiff), !imageData.isEmpty {
            try repository.insert(record(for: .init(
                contentType: .image,
                previewText: "Image \(ByteCountFormatter.string(fromByteCount: Int64(imageData.count), countStyle: .file))",
                searchableText: "image",
                sizeBytes: Int64(imageData.count)
            )))
        }
    }

    private func record(for item: NormalizedClipboardItem) -> ClipboardItemRecord {
        let now = Date()
        let hash = stableHash(for: "\(item.contentType.rawValue):\(item.searchableText):\(item.sizeBytes)")
        return ClipboardItemRecord(
            id: UUID().uuidString,
            contentType: item.contentType,
            previewText: item.previewText,
            searchableText: item.searchableText,
            contentHash: hash,
            sourceAppBundleID: NSWorkspace.shared.frontmostApplication?.bundleIdentifier,
            sourceAppName: NSWorkspace.shared.frontmostApplication?.localizedName,
            createdAt: now,
            lastUsedAt: nil,
            pinned: false,
            sizeBytes: item.sizeBytes,
            cachePath: item.cachePath,
            originalFileURL: item.originalFileURL,
            expiresAt: nil,
            deletedAt: nil
        )
    }

    private func preview(_ text: String) -> String {
        let collapsed = text
            .split(whereSeparator: \.isNewline)
            .joined(separator: " ")
        return String(collapsed.prefix(120))
    }

    private func stableHash(for value: String) -> String {
        String(value.unicodeScalars.reduce(UInt64(14_695_981_039_346_656_037)) { hash, scalar in
            (hash ^ UInt64(scalar.value)) &* 1_099_511_628_211
        })
    }
}
#endif
