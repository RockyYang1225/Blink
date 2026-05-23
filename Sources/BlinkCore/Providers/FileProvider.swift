import Foundation

public struct FileProvider: CommandProvider {
    public let id = "file"
    public let displayName = "Files"

    private let fileURLs: [URL]
    private let fileActions: FileActionService

    public init(fileURLs: [URL] = [], fileActions: FileActionService = FileActionService()) {
        self.fileURLs = fileURLs
        self.fileActions = fileActions
    }

    public func search(_ query: CommandQuery) async -> [CommandResult] {
        guard !query.isEmpty else {
            return []
        }

        return fileURLs
            .filter { $0.lastPathComponent.localizedCaseInsensitiveContains(query.text) }
            .prefix(20)
            .map { url in
                CommandResult(
                    id: "file-\(url.path)",
                    providerID: id,
                    title: url.lastPathComponent,
                    subtitle: url.deletingLastPathComponent().path,
                    score: 0.65,
                    primaryAction: .open,
                    secondaryActions: [.reveal, .copy, .move, .rename],
                    payload: .fileURL(url)
                )
            }
    }

    public func execute(_ result: CommandResult, action: CommandAction) async -> CommandExecutionResult {
        guard case let .fileURL(url) = result.payload else {
            return .validationFailed("File result has no URL")
        }

        switch action.id {
        case CommandAction.open.id:
            return fileActions.open(url)
        case CommandAction.reveal.id:
            return fileActions.reveal(url)
        default:
            return .validationFailed("File action \(action.id) needs more input")
        }
    }
}
