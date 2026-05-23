import Foundation
import GRDB

public final class ClipboardRepository: @unchecked Sendable {
    private let database: BlinkDatabase

    public init(database: BlinkDatabase) {
        self.database = database
    }

    public func insert(_ record: ClipboardItemRecord) throws {
        try database.queue.write { db in
            var mutableRecord = record
            try mutableRecord.insert(db, onConflict: .replace)
            try db.execute(sql: "DELETE FROM clipboard_items_fts WHERE id = ?", arguments: [record.id])
            try db.execute(
                sql: "INSERT INTO clipboard_items_fts(id, preview_text, searchable_text) VALUES (?, ?, ?)",
                arguments: [record.id, record.previewText, record.searchableText]
            )
        }
    }

    public func recent(limit: Int) throws -> [ClipboardItemRecord] {
        try database.queue.read { db in
            try ClipboardItemRecord.fetchAll(
                db,
                sql: """
                    SELECT * FROM clipboard_items
                    WHERE deleted_at IS NULL
                    ORDER BY pinned DESC, created_at DESC
                    LIMIT ?
                    """,
                arguments: [limit]
            )
        }
    }

    public func search(_ text: String, limit: Int) throws -> [ClipboardItemRecord] {
        let query = ftsQuery(for: text)
        guard !query.isEmpty else {
            return try recent(limit: limit)
        }

        return try database.queue.read { db in
            try ClipboardItemRecord.fetchAll(
                db,
                sql: """
                    SELECT clipboard_items.*
                    FROM clipboard_items
                    JOIN clipboard_items_fts ON clipboard_items_fts.id = clipboard_items.id
                    WHERE clipboard_items_fts MATCH ?
                      AND clipboard_items.deleted_at IS NULL
                    ORDER BY clipboard_items.pinned DESC, clipboard_items.created_at DESC
                    LIMIT ?
                    """,
                arguments: [query, limit]
            )
        }
    }

    public func clear() throws {
        try database.queue.write { db in
            try db.execute(sql: "DELETE FROM clipboard_items_fts")
            try db.execute(sql: "DELETE FROM clipboard_items")
        }
    }

    private func ftsQuery(for text: String) -> String {
        text
            .lowercased()
            .split { !$0.isLetter && !$0.isNumber }
            .map { "\($0)*" }
            .joined(separator: " ")
    }
}
