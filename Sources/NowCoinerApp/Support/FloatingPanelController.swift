import SwiftUI
import AppKit

@MainActor
final class FloatingPanelController {
    private var panel: NSPanel?

    func toggle<Content: View>(@ViewBuilder content: () -> Content) {
        if let panel, panel.isVisible {
            panel.orderOut(nil)
            return
        }

        show(content: AnyView(content()))
    }

    private func show(content: AnyView) {
        let panel: NSPanel

        if let existing = self.panel {
            panel = existing
        } else {
            let created = NSPanel(
                contentRect: NSRect(x: 0, y: 0, width: 340, height: 460),
                styleMask: [.titled, .fullSizeContentView, .nonactivatingPanel],
                backing: .buffered,
                defer: false
            )
            created.titleVisibility = .hidden
            created.titlebarAppearsTransparent = true
            created.isFloatingPanel = true
            created.level = .statusBar
            created.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
            created.isReleasedWhenClosed = false
            created.standardWindowButton(.closeButton)?.isHidden = true
            created.standardWindowButton(.miniaturizeButton)?.isHidden = true
            created.standardWindowButton(.zoomButton)?.isHidden = true
            self.panel = created
            panel = created
        }

        panel.contentView = NSHostingView(rootView: content)
        panel.center()
        NSApp.activate(ignoringOtherApps: true)
        panel.orderFrontRegardless()
    }
}
