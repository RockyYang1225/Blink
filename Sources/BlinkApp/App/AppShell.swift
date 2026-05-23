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
        do {
            let paths = try AppPaths.live()
            database = try BlinkDatabase.at(paths.databaseURL)
        } catch {
            database = try! BlinkDatabase.inMemory()
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
            onToggleLauncher: { windowController.toggle() },
            onClearHistory: { try? clipboardRepository.clear() },
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
                try? clipboard?.captureIfChanged()
            }
        }
        _ = hotkeyController
        _ = menuBarController
    }
}
