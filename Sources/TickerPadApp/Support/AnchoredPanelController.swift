import SwiftUI
import AppKit

@MainActor
final class AnchoredPanelController {
    static let windowIdentifier = "tickerpad.anchored.panel"

    private var panel: InputFriendlyPanel?

    func show<Content: View>(
        anchor: MenuAnchor,
        panelSize: CGSize,
        @ViewBuilder content: () -> Content
    ) {
        let panel = ensurePanel(size: panelSize)
        panel.contentView = NSHostingView(rootView: AnyView(content()))

        let targetFrame = computeFrame(anchor: anchor, size: panelSize)
        let startFrame = NSRect(x: targetFrame.origin.x, y: targetFrame.origin.y + 8, width: targetFrame.width, height: targetFrame.height)

        panel.setFrame(startFrame, display: false)
        panel.alphaValue = 0
        panel.makeKeyAndOrderFront(nil)

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.16
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            panel.animator().alphaValue = 1
            panel.animator().setFrame(targetFrame, display: true)
        }

        NSApp.activate(ignoringOtherApps: true)
    }

    func close() {
        panel?.orderOut(nil)
    }

    var window: NSWindow? {
        panel
    }

    private func ensurePanel(size: CGSize) -> InputFriendlyPanel {
        if let panel {
            return panel
        }

        let created = InputFriendlyPanel(
            contentRect: NSRect(x: 0, y: 0, width: size.width, height: size.height),
            styleMask: [.titled, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        created.identifier = NSUserInterfaceItemIdentifier(Self.windowIdentifier)
        created.titleVisibility = .hidden
        created.titlebarAppearsTransparent = true
        created.isFloatingPanel = true
        created.level = .floating
        created.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        created.isReleasedWhenClosed = false
        created.backgroundColor = .clear
        created.isOpaque = false
        created.hasShadow = true
        created.hidesOnDeactivate = false
        created.standardWindowButton(.closeButton)?.isHidden = true
        created.standardWindowButton(.miniaturizeButton)?.isHidden = true
        created.standardWindowButton(.zoomButton)?.isHidden = true

        self.panel = created
        return created
    }

    private func computeFrame(anchor: MenuAnchor, size: CGSize) -> NSRect {
        let screen = anchor.screen ?? NSScreen.main ?? NSScreen.screens.first
        let visible = screen?.visibleFrame ?? NSRect(x: 0, y: 0, width: size.width, height: size.height)

        let y = visible.maxY - size.height - 4
        let x = max(visible.minX + 8, min(anchor.x - size.width / 2, visible.maxX - size.width - 8))
        return NSRect(x: x, y: y, width: size.width, height: size.height)
    }
}

private final class InputFriendlyPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}
