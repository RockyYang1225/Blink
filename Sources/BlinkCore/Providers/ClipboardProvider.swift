import Foundation

public struct ClipboardProvider: CommandProvider {
    public let id = "clipboard"
    public let displayName = "Clipboard"

    private let repository: ClipboardRepository
    private let writer: any ClipboardWriting

    public init(repository: ClipboardRepository, writer: any ClipboardWriting = NoopClipboardWriter()) {
        self.repository = repository
        self.writer = writer
    }

    public func search(_ query: CommandQuery) async -> [CommandResult] {
        do {
            let records = try repository.search(query.text, limit: 20)
            return records.enumerated().map { index, record in
                result(for: record, score: max(0.5, 0.9 - (Double(index) * 0.01)))
            }
        } catch {
            return [
                CommandResult(
                    id: "clipboard-error",
                    providerID: id,
                    title: "Clipboard search failed",
                    subtitle: error.localizedDescription,
                    score: 0,
                    primaryAction: .copy
                )
            ]
        }
    }

    public func execute(_ result: CommandResult, action: CommandAction) async -> CommandExecutionResult {
        guard action.id == CommandAction.copy.id else {
            return .validationFailed("Unsupported clipboard action \(action.id)")
        }

        guard case let .clipboardItem(itemID) = result.payload else {
            return .validationFailed("Clipboard result has no item id")
        }

        do {
            guard let record = try repository.record(id: itemID) else {
                return .missingResource("Clipboard item \(itemID) is missing")
            }

            guard record.contentType == .text else {
                return .validationFailed("Only text clipboard copy-back is implemented")
            }

            let didWrite = await writer.writeText(record.searchableText)
            return didWrite
                ? .success(message: "Copied clipboard item")
                : .failed("System clipboard rejected text")
        } catch {
            return .failed(error.localizedDescription)
        }
    }

    private func result(for record: ClipboardItemRecord, score: Double) -> CommandResult {
        CommandResult(
            id: "clipboard-\(record.id)",
            providerID: id,
            title: record.previewText,
            subtitle: subtitle(for: record),
            score: score,
            primaryAction: .copy,
            secondaryActions: [],
            payload: .clipboardItem(record.id)
        )
    }

    private func subtitle(for record: ClipboardItemRecord) -> String {
        switch record.contentType {
        case .text:
            return "Clipboard text"
        case .image:
            return "Clipboard image"
        case .file:
            return "Clipboard file"
        }
    }
}
