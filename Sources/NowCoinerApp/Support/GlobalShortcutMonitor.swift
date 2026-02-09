import AppKit

@MainActor
final class GlobalShortcutMonitor {
    private var globalToken: Any?
    private var localToken: Any?
    private var shortcut = ShortcutDefinition.defaultValue
    private let handler: () -> Void

    init(handler: @escaping () -> Void) {
        self.handler = handler
    }

    func start() {
        stop()

        globalToken = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            self?.handle(event)
        }

        localToken = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            self?.handle(event)
            return event
        }
    }

    func stop() {
        if let globalToken {
            NSEvent.removeMonitor(globalToken)
            self.globalToken = nil
        }

        if let localToken {
            NSEvent.removeMonitor(localToken)
            self.localToken = nil
        }
    }

    func update(shortcutText: String) {
        shortcut = ShortcutDefinition(shortcutText: shortcutText)
    }

    private func handle(_ event: NSEvent) {
        guard shortcut.matches(event) else { return }
        handler()
    }
}

private struct ShortcutDefinition {
    let key: String
    let requireCommand: Bool
    let requireShift: Bool
    let requireOption: Bool
    let requireControl: Bool

    static let defaultValue = ShortcutDefinition(shortcutText: "⌘⇧C")

    init(shortcutText: String) {
        let upper = shortcutText.uppercased()
        self.requireCommand = upper.contains("⌘")
        self.requireShift = upper.contains("⇧")
        self.requireOption = upper.contains("⌥")
        self.requireControl = upper.contains("⌃")

        let letters = upper.filter { $0.isLetter || $0.isNumber }
        self.key = letters.isEmpty ? "C" : String(letters.suffix(1))
    }

    func matches(_ event: NSEvent) -> Bool {
        let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)

        if requireCommand != flags.contains(.command) { return false }
        if requireShift != flags.contains(.shift) { return false }
        if requireOption != flags.contains(.option) { return false }
        if requireControl != flags.contains(.control) { return false }

        let pressed = (event.charactersIgnoringModifiers ?? "").uppercased()
        return pressed == key
    }
}
