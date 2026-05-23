import Foundation
import GRDB

public struct ClipboardItemRecord: Codable, FetchableRecord, MutablePersistableRecord, Equatable, Sendable {
    public static let databaseTableName = "clipboard_items"

    public var id: String
    public var contentType: ContentType
    public var previewText: String
    public var searchableText: String
    public var contentHash: String
    public var sourceAppBundleID: String?
    public var sourceAppName: String?
    public var createdAt: Date
    public var lastUsedAt: Date?
    public var pinned: Bool
    public var sizeBytes: Int64
    public var cachePath: String?
    public var originalFileURL: URL?
    public var expiresAt: Date?
    public var deletedAt: Date?

    public enum ContentType: String, Codable, Sendable {
        case text
        case image
        case file
    }

    enum CodingKeys: String, CodingKey {
        case id
        case contentType = "content_type"
        case previewText = "preview_text"
        case searchableText = "searchable_text"
        case contentHash = "content_hash"
        case sourceAppBundleID = "source_app_bundle_id"
        case sourceAppName = "source_app_name"
        case createdAt = "created_at"
        case lastUsedAt = "last_used_at"
        case pinned
        case sizeBytes = "size_bytes"
        case cachePath = "cache_path"
        case originalFileURL = "original_file_url"
        case expiresAt = "expires_at"
        case deletedAt = "deleted_at"
    }

    public init(
        id: String,
        contentType: ContentType,
        previewText: String,
        searchableText: String,
        contentHash: String,
        sourceAppBundleID: String?,
        sourceAppName: String?,
        createdAt: Date,
        lastUsedAt: Date?,
        pinned: Bool,
        sizeBytes: Int64,
        cachePath: String?,
        originalFileURL: URL?,
        expiresAt: Date?,
        deletedAt: Date?
    ) {
        self.id = id
        self.contentType = contentType
        self.previewText = previewText
        self.searchableText = searchableText
        self.contentHash = contentHash
        self.sourceAppBundleID = sourceAppBundleID
        self.sourceAppName = sourceAppName
        self.createdAt = createdAt
        self.lastUsedAt = lastUsedAt
        self.pinned = pinned
        self.sizeBytes = sizeBytes
        self.cachePath = cachePath
        self.originalFileURL = originalFileURL
        self.expiresAt = expiresAt
        self.deletedAt = deletedAt
    }
}
