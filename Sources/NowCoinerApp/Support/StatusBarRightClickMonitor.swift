import AppKit

@MainActor
final class StatusBarRightClickMonitor {
    private var monitor: Any?
    private let actionTarget: ActionTarget

    init(onOpenSettings: @escaping () -> Void, onQuit: @escaping () -> Void) {
        self.actionTarget = ActionTarget(onOpenSettings: onOpenSettings, onQuit: onQuit)
    }

    func start() {
        guard monitor == nil else { return }
        monitor = NSEvent.addLocalMonitorForEvents(matching: [.rightMouseDown]) { [weak self] event in
            guard let self else { return event }
            return self.handle(event: event)
        }
    }

    func stop() {
        guard let monitor else { return }
        NSEvent.removeMonitor(monitor)
        self.monitor = nil
    }

    private func handle(event: NSEvent) -> NSEvent? {
        guard let window = event.window else { return event }
        let windowClassName = String(describing: type(of: window))
        guard windowClassName.contains("StatusBar") else { return event }

        let menu = NSMenu()

        let settingsItem = NSMenuItem(title: "设置", action: #selector(ActionTarget.openSettings), keyEquivalent: "")
        settingsItem.target = actionTarget
        menu.addItem(settingsItem)
        menu.addItem(.separator())

        let quitItem = NSMenuItem(title: "退出", action: #selector(ActionTarget.quitApp), keyEquivalent: "")
        quitItem.target = actionTarget
        menu.addItem(quitItem)

        if let contentView = window.contentView {
            menu.popUp(positioning: nil, at: event.locationInWindow, in: contentView)
            return nil
        }

        return event
    }
}

@MainActor
private final class ActionTarget: NSObject {
    private let onOpenSettings: () -> Void
    private let onQuit: () -> Void

    init(onOpenSettings: @escaping () -> Void, onQuit: @escaping () -> Void) {
        self.onOpenSettings = onOpenSettings
        self.onQuit = onQuit
    }

    @objc func openSettings() {
        onOpenSettings()
    }

    @objc func quitApp() {
        onQuit()
    }
}
