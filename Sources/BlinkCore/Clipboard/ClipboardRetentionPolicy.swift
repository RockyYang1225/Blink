import Foundation

public struct ClipboardRetentionCandidate: Equatable, Sendable {
    public let id: String
    public let createdAt: Date
    public let pinned: Bool
    public let sizeBytes: Int64
    public let cachePath: String?

    public init(id: String, createdAt: Date, pinned: Bool, sizeBytes: Int64, cachePath: String?) {
        self.id = id
        self.createdAt = createdAt
        self.pinned = pinned
        self.sizeBytes = sizeBytes
        self.cachePath = cachePath
    }
}

public struct ClipboardRetentionDecision: Equatable, Sendable {
    public let ids: [String]
    public let cachePaths: [String]

    public init(ids: [String], cachePaths: [String]) {
        self.ids = ids
        self.cachePaths = cachePaths
    }
}

public struct ClipboardRetentionPolicy: Sendable {
    public let maxItemCount: Int
    public let maxRetentionDays: Int
    public let maxCacheBytes: Int64

    public init(maxItemCount: Int, maxRetentionDays: Int, maxCacheBytes: Int64) {
        self.maxItemCount = maxItemCount
        self.maxRetentionDays = maxRetentionDays
        self.maxCacheBytes = maxCacheBytes
    }

    public func itemsToRemove(
        from items: [ClipboardRetentionCandidate],
        now: Date = Date()
    ) -> ClipboardRetentionDecision {
        var idsToRemove: Set<String> = []

        let expirationDate = now.addingTimeInterval(-Double(maxRetentionDays) * 86_400)
        for item in items where !item.pinned && item.createdAt < expirationDate {
            idsToRemove.insert(item.id)
        }

        let remainingAfterAge = items.filter { !idsToRemove.contains($0.id) }
        if remainingAfterAge.count > maxItemCount {
            let removable = remainingAfterAge
                .filter { !$0.pinned }
                .sorted { $0.createdAt < $1.createdAt }
            let overflow = remainingAfterAge.count - maxItemCount
            for item in removable.prefix(overflow) {
                idsToRemove.insert(item.id)
            }
        }

        var cacheTotal = items
            .filter { !idsToRemove.contains($0.id) }
            .reduce(Int64(0)) { $0 + max(0, $1.sizeBytes) }

        let cacheRemovable = items
            .filter { !$0.pinned && !idsToRemove.contains($0.id) && $0.cachePath != nil }
            .sorted { $0.createdAt < $1.createdAt }

        for item in cacheRemovable where cacheTotal > maxCacheBytes {
            idsToRemove.insert(item.id)
            cacheTotal -= max(0, item.sizeBytes)
        }

        let sortedIDs = items
            .filter { idsToRemove.contains($0.id) }
            .sorted { $0.createdAt < $1.createdAt }
            .map(\.id)

        let cachePaths = items
            .filter { idsToRemove.contains($0.id) }
            .compactMap(\.cachePath)

        return ClipboardRetentionDecision(ids: sortedIDs, cachePaths: cachePaths)
    }
}
