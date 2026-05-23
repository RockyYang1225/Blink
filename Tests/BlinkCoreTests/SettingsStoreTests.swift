import XCTest
@testable import BlinkCore

final class SettingsStoreTests: XCTestCase {
    func testLoadsDefaultSettingsWhenFileDoesNotExist() throws {
        let store = SettingsStore(url: temporaryDirectory().appendingPathComponent("settings.json"))

        let settings = try store.load()

        XCTAssertEqual(settings.maxItemCount, 500)
        XCTAssertTrue(settings.clipboardRecordingEnabled)
        XCTAssertEqual(settings.hotkeyName, "Option-Space")
    }

    func testSavesAndLoadsSettings() throws {
        let store = SettingsStore(url: temporaryDirectory().appendingPathComponent("settings.json"))
        let settings = BlinkSettings(
            hotkeyName: "Control-Space",
            clipboardRecordingEnabled: false,
            maxItemCount: 100,
            maxRetentionDays: 7,
            maxCacheBytes: 1_000,
            excludedBundleIDs: ["com.example.Secret"],
            excludedContentTypes: ["image"]
        )

        try store.save(settings)

        XCTAssertEqual(try store.load(), settings)
    }

    private func temporaryDirectory() -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("BlinkSettingsTests-\(UUID().uuidString)", isDirectory: true)
        try! FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }
}
