import Foundation

public protocol CommandProvider: Sendable {
    var id: String { get }
    var displayName: String { get }

    func search(_ query: CommandQuery) async -> [CommandResult]
    func execute(_ result: CommandResult, action: CommandAction) async -> CommandExecutionResult
}
