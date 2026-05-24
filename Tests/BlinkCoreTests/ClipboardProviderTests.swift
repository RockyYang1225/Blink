import XCTest
@testable import BlinkCore

private final class CapturingClipboardWriter: ClipboardWriting, @unchecked Sendable {
    private(set) var text: String?

    func writeText(_ text: String) async -> Bool {
        self.text = text
        return true
    }
}

final class ClipboardProviderTests: XCTestCase {
    func testSearchReturnsClipboardResults() async throws {
        let repository = try makeRepository()
        try repository.insert(record(id: "clip-1", previewText: "Secret token", searchableText: "secret token"))
        let provider = ClipboardProvider(repository: repository, writer: CapturingClipboardWriter())

        let results = await provider.search(CommandQuery(text: "secret"))

        XCTAssertEqual(results.first?.id, "clipboard-clip-1")
        XCTAssertEqual(results.first?.title, "Secret token")
        XCTAssertEqual(results.first?.primaryAction, .copy)
    }

    func testSearchScoresFollowRepositoryOrderSoNewestStaysFirst() async throws {
        let repository = try makeRepository()
        try repository.insert(record(
            id: "older-pinned",
            previewText: "A older token",
            searchableText: "token older",
            createdAt: Date(timeIntervalSince1970: 1),
            pinned: true
        ))
        try repository.insert(record(
            id: "newer",
            previewText: "Z newer token",
            searchableText: "token newer",
            createdAt: Date(timeIntervalSince1970: 2)
        ))
        let provider = ClipboardProvider(repository: repository, writer: CapturingClipboardWriter())

        let results = await provider.search(CommandQuery(text: "token"))

        XCTAssertEqual(results.map(\.id), ["clipboard-newer", "clipboard-older-pinned"])
        XCTAssertGreaterThan(results[0].score, results[1].score)
    }

    func testExecuteCopiesTextBackToClipboardWriter() async throws {
        let repository = try makeRepository()
        try repository.insert(record(id: "clip-1", previewText: "Secret token", searchableText: "secret token"))
        let writer = CapturingClipboardWriter()
        let provider = ClipboardProvider(repository: repository, writer: writer)
        let result = CommandResult(
            id: "clipboard-clip-1",
            providerID: provider.id,
            title: "Secret token",
            subtitle: "Clipboard text",
            score: 1,
            primaryAction: .copy,
            payload: .clipboardItem("clip-1")
        )

        let execution = await provider.execute(result, action: .copy)

        XCTAssertEqual(execution, .success(message: "Copied clipboard item"))
        XCTAssertEqual(writer.text, "secret token")
    }

    private func makeRepository() throws -> ClipboardRepository {
        let database = try BlinkDatabase.inMemory()
        return ClipboardRepository(database: database)
    }

    private func record(id: String, previewText: String, searchableText: String) -> ClipboardItemRecord {
        record(id: id, previewText: previewText, searchableText: searchableText, createdAt: Date(timeIntervalSince1970: 1))
    }

    private func record(
        id: String,
        previewText: String,
        searchableText: String,
        createdAt: Date,
        pinned: Bool = false
    ) -> ClipboardItemRecord {
        ClipboardItemRecord(
            id: id,
            contentType: .text,
            previewText: previewText,
            searchableText: searchableText,
            contentHash: "hash-\(id)",
            sourceAppBundleID: nil,
            sourceAppName: nil,
            createdAt: createdAt,
            lastUsedAt: nil,
            pinned: pinned,
            sizeBytes: Int64(searchableText.utf8.count),
            cachePath: nil,
            originalFileURL: nil,
            expiresAt: nil,
            deletedAt: nil
        )
    }
}
