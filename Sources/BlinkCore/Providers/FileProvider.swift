import Foundation

public struct FileProvider: CommandProvider, @unchecked Sendable {
    public let id = "file"
    public let displayName = "Files"

    private let fileURLs: [URL]
    private let searchRoots: [URL]
    private let maxDepth: Int
    private let fileActions: FileActionService
    private let fileManager: FileManager

    public init(
        fileURLs: [URL] = [],
        searchRoots: [URL] = FileProvider.defaultSearchRoots(),
        maxDepth: Int = 2,
        fileActions: FileActionService = FileActionService(),
        fileManager: FileManager = .default
    ) {
        self.fileURLs = fileURLs
        self.searchRoots = searchRoots
        self.maxDepth = maxDepth
        self.fileActions = fileActions
        self.fileManager = fileManager
    }

    public func search(_ query: CommandQuery) async -> [CommandResult] {
        guard !query.isEmpty else {
            return []
        }

        return candidateURLs()
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

    private func candidateURLs() -> [URL] {
        var seen = Set<String>()
        var urls: [URL] = []

        for url in fileURLs + scanRoots() {
            guard !url.lastPathComponent.hasPrefix(".") else {
                continue
            }
            guard seen.insert(url.path).inserted else {
                continue
            }
            urls.append(url)
        }

        return urls
    }

    private func scanRoots() -> [URL] {
        searchRoots.flatMap { scan(root: $0, depth: 0) }
    }

    private func scan(root: URL, depth: Int) -> [URL] {
        guard depth <= maxDepth else {
            return []
        }

        guard let children = try? fileManager.contentsOfDirectory(
            at: root,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles, .skipsPackageDescendants]
        ) else {
            return []
        }

        var urls: [URL] = []
        for child in children {
            urls.append(child)
            let isDirectory = (try? child.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) ?? false
            if isDirectory {
                urls.append(contentsOf: scan(root: child, depth: depth + 1))
            }
        }
        return urls
    }

    public static func defaultSearchRoots() -> [URL] {
        let home = FileManager.default.homeDirectoryForCurrentUser
        return [
            home.appendingPathComponent("Desktop", isDirectory: true),
            home.appendingPathComponent("Documents", isDirectory: true),
            home.appendingPathComponent("Downloads", isDirectory: true)
        ]
    }
}
