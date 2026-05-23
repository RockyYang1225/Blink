import Foundation

#if canImport(AppKit)
import AppKit
#endif

public struct AppProvider: CommandProvider, @unchecked Sendable {
    public let id = "app"
    public let displayName = "Applications"

    private let applicationDirectories: [URL]
    private let fileManager: FileManager

    public init(
        applicationDirectories: [URL] = [
            URL(fileURLWithPath: "/Applications", isDirectory: true),
            URL(fileURLWithPath: "/System/Applications", isDirectory: true),
            FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Applications", isDirectory: true)
        ],
        fileManager: FileManager = .default
    ) {
        self.applicationDirectories = applicationDirectories
        self.fileManager = fileManager
    }

    public func search(_ query: CommandQuery) async -> [CommandResult] {
        guard !query.isEmpty else {
            return []
        }

        let apps = applicationDirectories.flatMap { directory -> [URL] in
            guard let urls = try? fileManager.contentsOfDirectory(
                at: directory,
                includingPropertiesForKeys: [.isApplicationKey],
                options: [.skipsHiddenFiles]
            ) else {
                return []
            }
            return urls.filter { $0.pathExtension == "app" }
        }

        return apps
            .filter { $0.deletingPathExtension().lastPathComponent.localizedCaseInsensitiveContains(query.text) }
            .prefix(20)
            .map { url in
                CommandResult(
                    id: "app-\(url.path)",
                    providerID: id,
                    title: url.deletingPathExtension().lastPathComponent,
                    subtitle: url.path,
                    score: 0.8,
                    primaryAction: .open,
                    payload: .appURL(url)
                )
            }
    }

    public func execute(_ result: CommandResult, action: CommandAction) async -> CommandExecutionResult {
        guard action.id == CommandAction.open.id else {
            return .validationFailed("Unsupported app action \(action.id)")
        }
        guard case let .appURL(url) = result.payload else {
            return .validationFailed("App result has no URL")
        }

        #if canImport(AppKit)
        return NSWorkspace.shared.open(url)
            ? .success(message: "Opened app")
            : .failed("Failed to open app")
        #else
        return .success(message: "App URL exists")
        #endif
    }
}
