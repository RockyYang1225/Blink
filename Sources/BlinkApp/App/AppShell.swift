import AppKit
import BlinkCore
import Foundation

@MainActor
final class AppShell {
    private let launcherViewModel: LauncherViewModel
    private let launcherWindowController: LauncherWindowController
    private let hotkeyController: HotkeyController
    private let menuBarController: MenuBarController
    private let clipboardService: ClipboardService?
    private var clipboardTimer: Timer?

    init() {
        let database: BlinkDatabase
        var paths: AppPaths
        var logger: DiagnosticsLogger
        do {
            paths = try AppPaths.live()
            logger = DiagnosticsLogger(logURL: paths.logURL)
            database = try BlinkDatabase.at(paths.databaseURL)
        } catch {
            let fallback = FileManager.default.temporaryDirectory.appendingPathComponent("BlinkFallback", isDirectory: true)
            paths = AppPaths(applicationSupportDirectory: fallback)
            logger = DiagnosticsLogger(logURL: paths.logURL)
            try? logger.append("Fell back to in-memory database: \(error.localizedDescription)")
            database = try! BlinkDatabase.inMemory()
        }

        let settingsStore = SettingsStore(url: paths.settingsURL)
        var settings = (try? settingsStore.load()) ?? .defaults
        if !FileManager.default.fileExists(atPath: paths.settingsURL.path) {
            try? settingsStore.save(settings)
        }

        let clipboardRepository = ClipboardRepository(database: database)
        let commandEngine = CommandEngine(providers: [
            AppProvider(),
            ClipboardProvider(repository: clipboardRepository, writer: SystemClipboardWriter()),
            TimestampProvider(),
            FileProvider()
        ])

        let viewModel = LauncherViewModel(commandEngine: commandEngine)
        let windowController = LauncherWindowController(viewModel: viewModel)
        let hotkey = HotkeyController {
            windowController.toggle()
        }
        let menu = MenuBarController(
            clipboardRecordingEnabled: settings.clipboardRecordingEnabled,
            onToggleLauncher: { windowController.toggle() },
            onToggleClipboardRecording: {
                settings.clipboardRecordingEnabled.toggle()
                do {
                    try settingsStore.save(settings)
                } catch {
                    try? logger.append("Failed to save clipboard recording state: \(error.localizedDescription)")
                }
                return settings.clipboardRecordingEnabled
            },
            onClearHistory: {
                do {
                    try clipboardRepository.clear()
                } catch {
                    try? logger.append("Failed to clear clipboard history: \(error.localizedDescription)")
                }
            },
            onOpenConfig: { NSWorkspace.shared.open(paths.settingsURL) },
            onOpenLogs: { NSWorkspace.shared.open(paths.logURL) },
            onQuit: { NSApp.terminate(nil) }
        )
        let clipboard = ClipboardService(repository: clipboardRepository)

        launcherViewModel = viewModel
        launcherWindowController = windowController
        hotkeyController = hotkey
        menuBarController = menu
        clipboardService = clipboard
        clipboardTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak clipboard] _ in
            Task { @MainActor in
                let currentSettings = (try? settingsStore.load()) ?? settings
                guard currentSettings.clipboardRecordingEnabled else {
                    return
                }
                try? clipboard?.captureIfChanged()
            }
        }
        _ = hotkeyController
        _ = menuBarController
    }
}
