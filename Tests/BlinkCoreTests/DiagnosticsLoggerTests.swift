import XCTest
@testable import BlinkCore

final class DiagnosticsLoggerTests: XCTestCase {
    func testAppendWritesTimestampedLine() throws {
        let directory = temporaryDirectory()
        let logger = DiagnosticsLogger(logURL: directory.appendingPathComponent("blink.log"))

        try logger.append("provider failed")

        let contents = try String(contentsOf: directory.appendingPathComponent("blink.log"), encoding: .utf8)
        XCTAssertTrue(contents.contains("provider failed"))
        XCTAssertTrue(contents.contains("Z "))
    }

    private func temporaryDirectory() -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("BlinkDiagnosticsTests-\(UUID().uuidString)", isDirectory: true)
        try! FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }
}
