import SwiftUI
import AppKit
import UniformTypeIdentifiers

// MARK: - Upload Screen
struct UploadScreen: View {
    @State private var uploadedURLs: [URL] = []

    var body: some View {
        ZStack {
            Brand.background

            VStack(spacing: 32) {
                SauronTitle()
                    .padding(.top, 24)

                Spacer()

                SauronPrimaryButton(title: "Upload", action: selectFiles)
                .buttonStyle(.plain)

                Spacer(minLength: 80)
            }
            .padding(.horizontal, 32)
        }
        .overlay(WindowConfigurator())
        .ignoresSafeArea()
    }

    private func selectFiles() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = true
        panel.allowedContentTypes = [.item]
        panel.begin { response in
            if response == .OK {
                uploadedURLs = panel.urls
            }
        }
    }
}

// MARK: - Window configuration for macOS
private struct WindowConfigurator: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView { NSView() }
    func updateNSView(_ view: NSView, context: Context) {
        DispatchQueue.main.async {
            if let window = view.window {
                window.titleVisibility = .hidden
                window.titlebarAppearsTransparent = true
                window.styleMask.insert(.fullSizeContentView)
                window.isOpaque = false
                window.backgroundColor = .clear
                window.isMovableByWindowBackground = true
            }
        }
    }
}

// No local utilities; uses global Brand and Color(hex:)

#Preview {
    UploadScreen()
        .frame(width: 600, height: 420)
}
