import XCTest
@testable import BlinkCore

final class ClipboardRetentionPolicyTests: XCTestCase {
    func testCountLimitRemovesOldestUnpinnedItems() {
        let policy = ClipboardRetentionPolicy(maxItemCount: 2, maxRetentionDays: 30, maxCacheBytes: 10_000)
        let items = [
            candidate("old", createdAt: 1),
            candidate("new", createdAt: 3),
            candidate("pinned", createdAt: 0, pinned: true),
            candidate("middle", createdAt: 2)
        ]

        let decision = policy.itemsToRemove(from: items, now: Date(timeIntervalSince1970: 100))

        XCTAssertEqual(decision.ids, ["old", "middle"])
    }

    func testAgeLimitRemovesExpiredUnpinnedItems() {
        let policy = ClipboardRetentionPolicy(maxItemCount: 10, maxRetentionDays: 1, maxCacheBytes: 10_000)
        let now = Date(timeIntervalSince1970: 172_800)
        let items = [
            candidate("expired", createdAt: 0),
            candidate("fresh", createdAt: 172_700),
            candidate("pinned-expired", createdAt: 0, pinned: true)
        ]

        let decision = policy.itemsToRemove(from: items, now: now)

        XCTAssertEqual(decision.ids, ["expired"])
    }

    func testCacheLimitRemovesOldestCachedItemsAndReturnsPaths() {
        let policy = ClipboardRetentionPolicy(maxItemCount: 10, maxRetentionDays: 30, maxCacheBytes: 100)
        let items = [
            candidate("old-image", createdAt: 1, sizeBytes: 80, cachePath: "/tmp/old"),
            candidate("new-image", createdAt: 2, sizeBytes: 50, cachePath: "/tmp/new")
        ]

        let decision = policy.itemsToRemove(from: items, now: Date(timeIntervalSince1970: 3))

        XCTAssertEqual(decision.ids, ["old-image"])
        XCTAssertEqual(decision.cachePaths, ["/tmp/old"])
    }

    private func candidate(
        _ id: String,
        createdAt: TimeInterval,
        pinned: Bool = false,
        sizeBytes: Int64 = 1,
        cachePath: String? = nil
    ) -> ClipboardRetentionCandidate {
        ClipboardRetentionCandidate(
            id: id,
            createdAt: Date(timeIntervalSince1970: createdAt),
            pinned: pinned,
            sizeBytes: sizeBytes,
            cachePath: cachePath
        )
    }
}
