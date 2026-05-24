import XCTest
@testable import BlinkApp
import BlinkCore

private struct EmptyQueryProvider: CommandProvider {
    let id = "clipboard"
    let displayName = "Clipboard"

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
    func testRefreshForPresentationShowsFeatureOptions() async {
        let engine = CommandEngine(providers: [EmptyQueryProvider()])
        let viewModel = LauncherViewModel(commandEngine: engine)

        await viewModel.refreshForPresentation()

        XCTAssertTrue(viewModel.isShowingFeatureOptions)
        XCTAssertEqual(viewModel.featureOptions.map(\.title), [
            "Clipboard History",
            "Timestamp Converter",
            "File Search",
            "Applications"
        ])
        XCTAssertEqual(viewModel.results, [])
    }

    func testActivatingClipboardHistoryLoadsRecentClipboardResults() async {
        let engine = CommandEngine(providers: [EmptyQueryProvider()])
        let viewModel = LauncherViewModel(commandEngine: engine)

        await viewModel.refreshForPresentation()
        await viewModel.activateSelectedFeature()

        XCTAssertFalse(viewModel.isShowingFeatureOptions)
        XCTAssertEqual(viewModel.activeFeature?.title, "Clipboard History")
        XCTAssertEqual(viewModel.results.map(\.title), ["Recent clipboard text"])
        XCTAssertEqual(viewModel.selectedIndex, 0)
        XCTAssertNil(viewModel.statusMessage)
    }

    func testEscapeFromFeatureReturnsToFeatureOptions() async {
        let engine = CommandEngine(providers: [EmptyQueryProvider()])
        let viewModel = LauncherViewModel(commandEngine: engine)

        await viewModel.refreshForPresentation()
        await viewModel.activateSelectedFeature()

        XCTAssertTrue(viewModel.exitFeature())
        XCTAssertTrue(viewModel.isShowingFeatureOptions)
        XCTAssertNil(viewModel.activeFeature)
        XCTAssertEqual(viewModel.results, [])
    }
}
