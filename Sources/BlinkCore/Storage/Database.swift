import Foundation
import GRDB

public struct BlinkDatabase {
    public let queue: DatabaseQueue

    public init(queue: DatabaseQueue) throws {
        self.queue = queue
        try Self.migrate(queue)
    }

    public static func inMemory() throws -> BlinkDatabase {
        try BlinkDatabase(queue: DatabaseQueue())
    }

    public static func at(_ url: URL) throws -> BlinkDatabase {
        try BlinkDatabase(queue: DatabaseQueue(path: url.path))
    }

    private static func migrate(_ queue: DatabaseQueue) throws {
        var migrator = DatabaseMigrator()

        migrator.registerMigration("createClipboardItems") { db in
            try db.create(table: "clipboard_items") { table in
                table.column("id", .text).primaryKey()
                table.column("content_type", .text).notNull()
                table.column("preview_text", .text).notNull()
                table.column("searchable_text", .text).notNull()
                table.column("content_hash", .text).notNull()
                table.column("source_app_bundle_id", .text)
                table.column("source_app_name", .text)
                table.column("created_at", .datetime).notNull()
                table.column("last_used_at", .datetime)
                table.column("pinned", .boolean).notNull().defaults(to: false)
                table.column("size_bytes", .integer).notNull().defaults(to: 0)
                table.column("cache_path", .text)
                table.column("original_file_url", .text)
                table.column("expires_at", .datetime)
                table.column("deleted_at", .datetime)
            }

            try db.create(index: "idx_clipboard_items_created_at", on: "clipboard_items", columns: ["created_at"])
            try db.create(index: "idx_clipboard_items_hash", on: "clipboard_items", columns: ["content_hash"])
            try db.execute(sql: """
                CREATE VIRTUAL TABLE clipboard_items_fts
                USING fts5(id UNINDEXED, preview_text, searchable_text)
                """)
        }

        try migrator.migrate(queue)
    }
}
