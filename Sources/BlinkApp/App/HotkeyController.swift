import KeyboardShortcuts

extension KeyboardShortcuts.Name {
    static let toggleLauncher = Self("toggleLauncher", default: .init(.space, modifiers: [.option]))
}

@MainActor
final class HotkeyController {
    init(onToggle: @escaping @MainActor () -> Void) {
        KeyboardShortcuts.onKeyUp(for: .toggleLauncher) {
            Task { @MainActor in
                onToggle()
            }
        }
    }
}
