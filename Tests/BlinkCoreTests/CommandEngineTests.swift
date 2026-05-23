import XCTest
@testable import BlinkCore

private struct StaticProvider: CommandProvider {
    let id: String
    let displayName: String
    let results: [CommandResult]
    let execution: CommandExecutionResult

    func search(_ query: CommandQuery) async -> [CommandResult] {
        results
    }

    func execute(_ result: CommandResult, action: CommandAction) async -> CommandExecutionResult {
        execution
    }
}

final class CommandEngineTests: XCTestCase {
    func testSearchMergesAndSortsByScoreDescending() async {
        let low = CommandResult(
            id: "low",
            providerID: "a",
            title: "Low",
            subtitle: "",
            score: 0.2,
            primaryAction: .open
        )
        let high = CommandResult(
            id: "high",
            providerID: "b",
            title: "High",
            subtitle: "",
            score: 0.9,
            primaryAction: .open
        )
        let engine = CommandEngine(providers: [
            StaticProvider(id: "a", displayName: "A", results: [low], execution: .success(message: "ok")),
            StaticProvider(id: "b", displayName: "B", results: [high], execution: .success(message: "ok"))
        ])

        let results = await engine.search(CommandQuery(text: "x"))

        XCTAssertEqual(results.map(\.id), ["high", "low"])
    }

    func testExecuteRoutesToOwningProvider() async {
        let result = CommandResult(
            id: "item",
            providerID: "owner",
            title: "Item",
            subtitle: "",
            score: 1,
            primaryAction: .open
        )
        let engine = CommandEngine(providers: [
            StaticProvider(id: "owner", displayName: "Owner", results: [result], execution: .success(message: "opened"))
        ])

        let execution = await engine.execute(result, action: .open)

        XCTAssertEqual(execution, .success(message: "opened"))
    }

    func testExecuteReportsMissingProvider() async {
        let result = CommandResult(
            id: "item",
            providerID: "missing",
            title: "Item",
            subtitle: "",
            score: 1,
            primaryAction: .open
        )
        let engine = CommandEngine(providers: [])

        let execution = await engine.execute(result, action: .open)

        XCTAssertEqual(execution, .missingResource("Provider missing is not registered"))
    }
}
