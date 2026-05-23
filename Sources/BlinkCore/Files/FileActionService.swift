import Foundation

#if canImport(AppKit)
import AppKit
#endif

public struct FileActionService: @unchecked Sendable {
    private let fileManager: FileManager

    public init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }

    public func open(_ url: URL) -> CommandExecutionResult {
        guard fileManager.fileExists(atPath: url.path) else {
            return .missingResource("File does not exist")
        }

        #if canImport(AppKit)
        return NSWorkspace.shared.open(url)
            ? .success(message: "Opened file")
            : .failed("Failed to open file")
        #else
        return .success(message: "File exists")
        #endif
    }

    public func reveal(_ url: URL) -> CommandExecutionResult {
        guard fileManager.fileExists(atPath: url.path) else {
            return .missingResource("File does not exist")
        }

        #if canImport(AppKit)
        NSWorkspace.shared.activateFileViewerSelecting([url])
        #endif
        return .success(message: "Revealed file")
    }

    public func copy(source: URL, to target: URL) -> CommandExecutionResult {
        guard fileManager.fileExists(atPath: source.path) else {
            return .missingResource("Source file does not exist")
        }
        guard !fileManager.fileExists(atPath: target.path) else {
            return .conflict("Target already exists")
        }

        do {
            try fileManager.copyItem(at: source, to: target)
            return .success(message: "Copied file")
        } catch {
            return .failed(error.localizedDescription)
        }
    }

    public func move(source: URL, to target: URL) -> CommandExecutionResult {
        guard fileManager.fileExists(atPath: source.path) else {
            return .missingResource("Source file does not exist")
        }
        guard !fileManager.fileExists(atPath: target.path) else {
            return .conflict("Target already exists")
        }

        do {
            try fileManager.moveItem(at: source, to: target)
            return .success(message: "Moved file")
        } catch {
            return .failed(error.localizedDescription)
        }
    }

    public func rename(source: URL, toName newName: String) -> CommandExecutionResult {
        guard !newName.isEmpty else {
            return .validationFailed("New name must not be empty")
        }
        guard !newName.contains("/") else {
            return .validationFailed("New name must not contain path separators")
        }

        let target = source.deletingLastPathComponent().appendingPathComponent(newName)
        let moveResult = move(source: source, to: target)

        if moveResult == .success(message: "Moved file") {
            return .success(message: "Renamed file")
        }
        return moveResult
    }
}
