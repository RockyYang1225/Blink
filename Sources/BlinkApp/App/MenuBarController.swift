import AppKit

@MainActor
final class MenuBarController {
    private let statusItem: NSStatusItem

    init(
        clipboardRecordingEnabled: Bool,
        onToggleLauncher: @escaping @MainActor () -> Void,
        onToggleClipboardRecording: @escaping @MainActor () -> Bool,
        onClearHistory: @escaping @MainActor () -> Void,
        onOpenConfig: @escaping @MainActor () -> Void,
        onOpenLogs: @escaping @MainActor () -> Void,
        onQuit: @escaping @MainActor () -> Void
    ) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.title = "Blink"

        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Show Blink", action: #selector(toggleLauncher), keyEquivalent: ""))
        let recordingItem = NSMenuItem(title: "", action: #selector(toggleClipboardRecording), keyEquivalent: "")
        menu.addItem(recordingItem)
        menu.addItem(NSMenuItem(title: "Clear Clipboard History", action: #selector(clearHistory), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Open Config", action: #selector(openConfig), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Open Logs", action: #selector(openLogs), keyEquivalent: ""))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q"))
        statusItem.menu = menu

        self.recordingItem = recordingItem
        self.onToggleLauncher = onToggleLauncher
        self.onToggleClipboardRecording = onToggleClipboardRecording
        self.onClearHistory = onClearHistory
        self.onOpenConfig = onOpenConfig
        self.onOpenLogs = onOpenLogs
        self.onQuit = onQuit
        updateClipboardRecordingTitle(isEnabled: clipboardRecordingEnabled)

        for item in menu.items {
            item.target = self
        }
    }

    private let recordingItem: NSMenuItem
    private let onToggleLauncher: @MainActor () -> Void
    private let onToggleClipboardRecording: @MainActor () -> Bool
    private let onClearHistory: @MainActor () -> Void
    private let onOpenConfig: @MainActor () -> Void
    private let onOpenLogs: @MainActor () -> Void
    private let onQuit: @MainActor () -> Void

    @objc private func toggleLauncher() {
        onToggleLauncher()
    }

    @objc private func clearHistory() {
        onClearHistory()
    }

    @objc private func toggleClipboardRecording() {
        let isEnabled = onToggleClipboardRecording()
        updateClipboardRecordingTitle(isEnabled: isEnabled)
    }

    @objc private func openConfig() {
        onOpenConfig()
    }

    @objc private func openLogs() {
        onOpenLogs()
    }

    @objc private func quit() {
        onQuit()
    }

    private func updateClipboardRecordingTitle(isEnabled: Bool) {
        recordingItem.title = isEnabled ? "Pause Clipboard Recording" : "Resume Clipboard Recording"
    }
}
