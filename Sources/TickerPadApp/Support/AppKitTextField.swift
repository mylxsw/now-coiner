import SwiftUI
import AppKit

struct AppKitTextField: NSViewRepresentable {
    @Binding var text: String
    let placeholder: String
    var onTextChanged: (() -> Void)? = nil

    final class Coordinator: NSObject, NSTextFieldDelegate {
        var parent: AppKitTextField

        init(parent: AppKitTextField) {
            self.parent = parent
        }

        func controlTextDidChange(_ obj: Notification) {
            guard let field = obj.object as? NSTextField else { return }
            parent.text = field.stringValue
            parent.onTextChanged?()
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeNSView(context: Context) -> NSTextField {
        let field = NSTextField(string: text)
        field.placeholderString = placeholder
        field.delegate = context.coordinator
        field.isBordered = false
        field.drawsBackground = false
        field.focusRingType = .none
        field.textColor = NSColor.white
        field.font = NSFont.systemFont(ofSize: 14, weight: .regular)

        // Retry until the window is key and accepts first responder.
        // The panel may not be key yet when makeNSView runs.
        scheduleFirstResponder(for: field)

        return field
    }

    private func scheduleFirstResponder(for field: NSTextField, attempts: Int = 10) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            if let window = field.window, window.isKeyWindow {
                window.makeFirstResponder(field)
            } else if attempts > 1 {
                self.scheduleFirstResponder(for: field, attempts: attempts - 1)
            }
        }
    }

    func updateNSView(_ nsView: NSTextField, context: Context) {
        if nsView.stringValue != text {
            nsView.stringValue = text
        }

        DispatchQueue.main.async {
            guard let window = nsView.window, window.isKeyWindow else { return }
            if window.firstResponder !== nsView.currentEditor() {
                window.makeFirstResponder(nsView)
            }
        }
    }
}
