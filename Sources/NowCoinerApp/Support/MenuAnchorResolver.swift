import AppKit

struct MenuAnchor {
    let x: CGFloat
    let screen: NSScreen?
}

@MainActor
enum MenuAnchorResolver {
    static func currentAnchor() -> MenuAnchor {
        let mouse = NSEvent.mouseLocation
        let screen = NSScreen.screens.first(where: { NSMouseInRect(mouse, $0.frame, false) }) ?? NSScreen.main

        let menuWindow = NSApp.windows
            .filter { $0.isVisible }
            .filter { $0.identifier?.rawValue != AnchoredPanelController.windowIdentifier }
            .max(by: { $0.frame.width < $1.frame.width })

        let x = menuWindow?.frame.midX ?? mouse.x
        return MenuAnchor(x: x, screen: screen)
    }

    static func closeAllAppWindows(excluding excluded: [NSWindow] = []) {
        let excludedSet = Set(excluded.map { ObjectIdentifier($0) })
        NSApp.windows
            .filter { $0.isVisible }
            .filter { !excludedSet.contains(ObjectIdentifier($0)) }
            .forEach { $0.orderOut(nil) }
    }

    static func endMenuTracking() {
        NSApp.sendAction(#selector(NSMenu.cancelTracking), to: nil, from: nil)
    }
}
