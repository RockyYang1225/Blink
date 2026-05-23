import XCTest
@testable import BlinkCore

final class CommandModelsTests: XCTestCase {
    func testCommandQueryTrimsWhitespace() {
        let query = CommandQuery(text: "  now  ")
        XCTAssertEqual(query.text, "now")
        XCTAssertFalse(query.isEmpty)
    }

    func testExecutionResultSuccessFlag() {
        XCTAssertTrue(CommandExecutionResult.success(message: "Copied").isSuccess)
        XCTAssertFalse(CommandExecutionResult.permissionDenied("No access").isSuccess)
    }
}
