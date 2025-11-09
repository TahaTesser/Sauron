import SwiftUI
import AppKit

// Applies global window styling: transparent title bar, unified content, movable background.
struct WindowConfigurator: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView { NSView() }
    func updateNSView(_ view: NSView, context: Context) {
        DispatchQueue.main.async {
            guard let window = view.window else { return }
            window.titleVisibility = .hidden
            window.titlebarAppearsTransparent = true
            window.styleMask.insert(.fullSizeContentView)
            window.isOpaque = false
            window.backgroundColor = .clear
            window.isMovableByWindowBackground = true
            // Hide any default SwiftUI-provided toolbar to keep the titlebar area clean.
            window.toolbar = nil
        }
    }
}
