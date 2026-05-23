import SwiftUI

@MainActor
final class LauncherWindowController {
    private let panel: NSPanel
    private let viewModel: LauncherViewModel

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
        NSApp.activate(ignoringOtherApps: true)
        panel.makeKeyAndOrderFront(nil)
    }

    func hide() {
        panel.orderOut(nil)
        viewModel.clearTransientState()
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
