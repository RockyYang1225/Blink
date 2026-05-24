import XCTest
@testable import BlinkApp
import BlinkCore

private struct EmptyQueryProvider: CommandProvider {
    let id = "empty-query"
    let displayName = "Empty Query"

    func search(_ query: CommandQuery) async -> [CommandResult] {
        guard query.isEmpty else {
            return []
        }

        return [
            CommandResult(
                id: "recent-clipboard",
                providerID: id,
                title: "Recent clipboard text",
                subtitle: "Clipboard text",
                score: 0.7,
                primaryAction: .copy,
                payload: .clipboardItem("clip-1")
            )
        ]
    }

    func execute(_ result: CommandResult, action: CommandAction) async -> CommandExecutionResult {
        .success(message: "Copied")
    }
}

@MainActor
final class LauncherViewModelTests: XCTestCase {
    func testRefreshForPresentationLoadsEmptyQueryResults() async {
        let engine = CommandEngine(providers: [EmptyQueryProvider()])
        let viewModel = LauncherViewModel(commandEngine: engine)

        await viewModel.refreshForPresentation()

        XCTAssertEqual(viewModel.results.map(\.title), ["Recent clipboard text"])
        XCTAssertEqual(viewModel.selectedIndex, 0)
        XCTAssertNil(viewModel.statusMessage)
    }
}
