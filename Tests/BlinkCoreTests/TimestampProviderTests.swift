import XCTest
@testable import BlinkCore

final class TimestampProviderTests: XCTestCase {
    func testUnixSecondsSearchReturnsDateResult() async {
        let provider = TimestampProvider(calendar: .gregorianUTC)

        let results = await provider.search(CommandQuery(text: "0"))

        XCTAssertEqual(results.first?.title, "1970-01-01 00:00:00 UTC")
        XCTAssertEqual(results.first?.payload, .text("1970-01-01 00:00:00 UTC"))
    }

    func testUnixMillisecondsSearchReturnsDateResult() async {
        let provider = TimestampProvider(calendar: .gregorianUTC)

        let results = await provider.search(CommandQuery(text: "1000"))

        XCTAssertTrue(results.contains { $0.subtitle == "Unix milliseconds" && $0.title == "1970-01-01 00:00:01 UTC" })
    }

    func testNowSearchReturnsCurrentTimeResult() async {
        let provider = TimestampProvider(calendar: .gregorianUTC)

        let results = await provider.search(CommandQuery(text: "now"))

        XCTAssertEqual(results.first?.subtitle, "Current time")
        XCTAssertEqual(results.first?.primaryAction, .copy)
    }

    func testExecuteCopiesTextPayload() async {
        let provider = TimestampProvider(calendar: .gregorianUTC)
        let result = CommandResult(
            id: "x",
            providerID: provider.id,
            title: "Value",
            subtitle: "",
            score: 1,
            primaryAction: .copy,
            payload: .text("Value")
        )

        let execution = await provider.execute(result, action: .copy)

        XCTAssertEqual(execution, .success(message: "Copied Value"))
    }
}

private extension Calendar {
    static var gregorianUTC: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }
}
