import SwiftUI

@MainActor
final class LauncherWindowController {
    private let panel: LauncherPanel
    private let viewModel: LauncherViewModel
    private var keyMonitor: Any?

    init(viewModel: LauncherViewModel) {
        self.viewModel = viewModel
        let rootView = LauncherView(viewModel: viewModel)
        let hostingController = NSHostingController(rootView: rootView)

        panel = LauncherPanel(
            contentRect: NSRect(x: 0, y: 0, width: 680, height: 420),
            styleMask: [.titled, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        panel.contentViewController = hostingController
        panel.isFloatingPanel = true
        panel.level = .normal
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
        Task { [viewModel] in
            await viewModel.refreshForPresentation()
        }
        NSApp.activate(ignoringOtherApps: true)
        DispatchQueue.main.async { [panel] in
            panel.deminiaturize(nil)
            panel.setIsVisible(true)
            panel.makeKeyAndOrderFront(nil)
            panel.orderFrontRegardless()
            panel.makeKey()
        }
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
        let screen = NSScreen.screens.sorted { lhs, rhs in
            if lhs.frame.minX == rhs.frame.minX {
                return lhs.frame.minY < rhs.frame.minY
            }
            return lhs.frame.minX < rhs.frame.minX
        }.first ?? NSScreen.main ?? NSScreen.screens.first
        guard let frame = screen?.visibleFrame else {
            return
        }

        let size = panel.frame.size
        let origin = NSPoint(
            x: 80,
            y: frame.maxY - size.height - 120
        )
        panel.setFrameOrigin(origin)
    }
}

private final class LauncherPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}
