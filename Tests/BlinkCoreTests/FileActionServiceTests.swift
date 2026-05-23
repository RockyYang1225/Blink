import XCTest
@testable import BlinkCore

final class FileActionServiceTests: XCTestCase {
    func testCopyReportsMissingSource() throws {
        let service = FileActionService(fileManager: .default)
        let temp = try temporaryDirectory()
        let missing = temp.appendingPathComponent("missing.txt")
        let target = temp.appendingPathComponent("target.txt")

        let result = service.copy(source: missing, to: target)

        XCTAssertEqual(result, .missingResource("Source file does not exist"))
    }

    func testCopyReportsTargetConflict() throws {
        let service = FileActionService(fileManager: .default)
        let temp = try temporaryDirectory()
        let source = temp.appendingPathComponent("source.txt")
        let target = temp.appendingPathComponent("target.txt")
        try "source".write(to: source, atomically: true, encoding: .utf8)
        try "target".write(to: target, atomically: true, encoding: .utf8)

        let result = service.copy(source: source, to: target)

        XCTAssertEqual(result, .conflict("Target already exists"))
    }

    func testRenameRejectsPathSeparators() throws {
        let service = FileActionService(fileManager: .default)
        let temp = try temporaryDirectory()
        let source = temp.appendingPathComponent("source.txt")
        try "source".write(to: source, atomically: true, encoding: .utf8)

        let result = service.rename(source: source, toName: "nested/name.txt")

        XCTAssertEqual(result, .validationFailed("New name must not contain path separators"))
    }

    func testRenameMovesFileInSameDirectory() throws {
        let service = FileActionService(fileManager: .default)
        let temp = try temporaryDirectory()
        let source = temp.appendingPathComponent("source.txt")
        let renamed = temp.appendingPathComponent("renamed.txt")
        try "source".write(to: source, atomically: true, encoding: .utf8)

        let result = service.rename(source: source, toName: "renamed.txt")

        XCTAssertEqual(result, .success(message: "Renamed file"))
        XCTAssertFalse(FileManager.default.fileExists(atPath: source.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: renamed.path))
    }

    private func temporaryDirectory() throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("BlinkTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }
}
