import AppKit

@MainActor
final class MenuBarController {
    private let statusItem: NSStatusItem

    init(
        onToggleLauncher: @escaping @MainActor () -> Void,
        onClearHistory: @escaping @MainActor () -> Void,
        onQuit: @escaping @MainActor () -> Void
    ) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.title = "Blink"

        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Show Blink", action: #selector(toggleLauncher), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Clear Clipboard History", action: #selector(clearHistory), keyEquivalent: ""))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q"))
        statusItem.menu = menu

        self.onToggleLauncher = onToggleLauncher
        self.onClearHistory = onClearHistory
        self.onQuit = onQuit

        for item in menu.items {
            item.target = self
        }
    }

    private let onToggleLauncher: @MainActor () -> Void
    private let onClearHistory: @MainActor () -> Void
    private let onQuit: @MainActor () -> Void

    @objc private func toggleLauncher() {
        onToggleLauncher()
    }

    @objc private func clearHistory() {
        onClearHistory()
    }

    @objc private func quit() {
        onQuit()
    }
}
