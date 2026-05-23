import SwiftUI

@MainActor
final class LauncherWindowController {
    private let panel: NSPanel
    private let viewModel: LauncherViewModel
    private var keyMonitor: Any?

    init(viewModel: LauncherViewModel) {
        self.viewModel = viewModel
        let rootView = LauncherView(viewModel: viewModel)
        let hostingController = NSHostingController(rootView: rootView)

        panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 680, height: 420),
            styleMask: [.nonactivatingPanel, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        panel.contentViewController = hostingController
        panel.isFloatingPanel = true
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.titleVisibility = .hidden
        panel.titlebarAppearsTransparent = true
        panel.isMovableByWindowBackground = true
        panel.hidesOnDeactivate = true
        panel.backgroundColor = .clear
    }

    func toggle() {
        panel.isVisible ? hide() : show()
    }

    func show() {
        positionOnActiveScreen()
        installKeyMonitor()
        NSApp.activate(ignoringOtherApps: true)
        panel.makeKeyAndOrderFront(nil)
    }

    func hide() {
        removeKeyMonitor()
        panel.orderOut(nil)
        viewModel.clearTransientState()
    }

    private func installKeyMonitor() {
        guard keyMonitor == nil else {
            return
        }

        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self, self.panel.isVisible, event.window === self.panel else {
                return event
            }

            return self.handleKeyDown(event) ? nil : event
        }
    }

    private func removeKeyMonitor() {
        if let keyMonitor {
            NSEvent.removeMonitor(keyMonitor)
        }
        keyMonitor = nil
    }

    private func handleKeyDown(_ event: NSEvent) -> Bool {
        let commandPressed = event.modifierFlags.intersection(.deviceIndependentFlagsMask).contains(.command)

        switch event.keyCode {
        case 53:
            if !viewModel.hideSecondaryActions() {
                hide()
            }
            return true
        case 125:
            viewModel.moveSelection(delta: 1)
            return true
        case 126:
            viewModel.moveSelection(delta: -1)
            return true
        case 36:
            if viewModel.isShowingSecondaryActions {
                viewModel.executeSelectedSecondaryAction()
            } else if commandPressed {
                viewModel.showSecondaryActions()
            } else {
                viewModel.executeSelected()
            }
            return true
        case 48:
            viewModel.showSecondaryActions()
            return true
        default:
            return false
        }
    }

    private func positionOnActiveScreen() {
        let screen = NSScreen.main ?? NSScreen.screens.first
        guard let frame = screen?.visibleFrame else {
            return
        }

        let size = panel.frame.size
        let origin = NSPoint(
            x: frame.midX - size.width / 2,
            y: frame.maxY - size.height - 120
        )
        panel.setFrameOrigin(origin)
    }
}
