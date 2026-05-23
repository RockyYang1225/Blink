import XCTest
@testable import BlinkCore

final class ClipboardRepositoryTests: XCTestCase {
    func testInsertAndRecentReturnsNewestFirstWithPinnedItemsFirst() throws {
        let repository = try makeRepository()
        let older = makeRecord(id: "older", previewText: "Older", createdAt: Date(timeIntervalSince1970: 1))
        let newer = makeRecord(id: "newer", previewText: "Newer", createdAt: Date(timeIntervalSince1970: 2))
        let pinned = makeRecord(id: "pinned", previewText: "Pinned", createdAt: Date(timeIntervalSince1970: 0), pinned: true)

        try repository.insert(older)
        try repository.insert(newer)
        try repository.insert(pinned)

        let recent = try repository.recent(limit: 10)

        XCTAssertEqual(recent.map(\.id), ["pinned", "newer", "older"])
    }

    func testSearchUsesFullTextIndex() throws {
        let repository = try makeRepository()
        try repository.insert(makeRecord(id: "a", previewText: "Meeting notes", searchableText: "alpha beta launch"))
        try repository.insert(makeRecord(id: "b", previewText: "Secret token", searchableText: "one-time secret value"))

        let matches = try repository.search("secret", limit: 10)

        XCTAssertEqual(matches.map(\.id), ["b"])
    }

    func testClearRemovesItemsAndSearchIndex() throws {
        let repository = try makeRepository()
        try repository.insert(makeRecord(id: "a", previewText: "Secret token", searchableText: "secret"))

        try repository.clear()

        XCTAssertEqual(try repository.recent(limit: 10), [])
        XCTAssertEqual(try repository.search("secret", limit: 10), [])
    }

    private func makeRepository() throws -> ClipboardRepository {
        let database = try BlinkDatabase.inMemory()
        return ClipboardRepository(database: database)
    }

    private func makeRecord(
        id: String,
        previewText: String,
        searchableText: String? = nil,
        createdAt: Date = Date(timeIntervalSince1970: 1),
        pinned: Bool = false
    ) -> ClipboardItemRecord {
        ClipboardItemRecord(
            id: id,
            contentType: .text,
            previewText: previewText,
            searchableText: searchableText ?? previewText,
            contentHash: "hash-\(id)",
            sourceAppBundleID: nil,
            sourceAppName: nil,
            createdAt: createdAt,
            lastUsedAt: nil,
            pinned: pinned,
            sizeBytes: Int64(previewText.utf8.count),
            cachePath: nil,
            originalFileURL: nil,
            expiresAt: nil,
            deletedAt: nil
        )
    }
}
