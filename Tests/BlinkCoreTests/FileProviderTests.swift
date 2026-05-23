import XCTest
@testable import BlinkCore

final class FileProviderTests: XCTestCase {
    func testSearchScansConfiguredRootDirectories() async throws {
        let root = try temporaryDirectory()
        let nested = root.appendingPathComponent("Notes", isDirectory: true)
        try FileManager.default.createDirectory(at: nested, withIntermediateDirectories: true)
        let target = nested.appendingPathComponent("Launch Plan.md")
        try "ship it".write(to: target, atomically: true, encoding: .utf8)
        let provider = FileProvider(searchRoots: [root], maxDepth: 2)

        let results = await provider.search(CommandQuery(text: "launch"))

        XCTAssertEqual(results.first?.title, "Launch Plan.md")
        guard case let .fileURL(foundURL) = results.first?.payload else {
            return XCTFail("Expected file URL payload")
        }
        XCTAssertEqual(foundURL.standardizedFileURL.path, target.standardizedFileURL.path)
    }

    func testSearchIgnoresHiddenFiles() async throws {
        let root = try temporaryDirectory()
        let hidden = root.appendingPathComponent(".secret")
        try "hidden".write(to: hidden, atomically: true, encoding: .utf8)
        let provider = FileProvider(searchRoots: [root], maxDepth: 1)

        let results = await provider.search(CommandQuery(text: "secret"))

        XCTAssertEqual(results, [])
    }

    private func temporaryDirectory() throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("BlinkFileProviderTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }
}
