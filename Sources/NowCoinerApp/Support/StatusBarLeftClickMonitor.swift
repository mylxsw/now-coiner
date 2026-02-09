import AppKit

@MainActor
final class StatusBarLeftClickMonitor {
    private var monitor: Any?
    private let onStatusBarClick: () -> Bool

    init(onStatusBarClick: @escaping () -> Bool) {
        self.onStatusBarClick = onStatusBarClick
    }

    func start() {
        guard monitor == nil else { return }
        monitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown]) { [weak self] event in
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

        // If any custom panel is currently visible, consume this click and close it.
        if onStatusBarClick() {
            return nil
        }

        return event
    }
}

