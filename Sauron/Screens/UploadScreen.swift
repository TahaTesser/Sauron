import SwiftUI
import AppKit
import UniformTypeIdentifiers

// MARK: - Upload Screen
struct UploadScreen: View {
    @State private var uploadedURLs: [URL] = []
    @State private var detectedItems: [PreviewSelectionItem] = []
    @State private var selectedRoot: URL?
    @State private var showSelection: Bool = false
    @State private var isScanning: Bool = false
    @State private var tip: String?
    @State private var isDropTarget: Bool = false

    var body: some View {
        ZStack {
            Brand.background

            VStack(spacing: 16) {
                Spacer()
                SauronTitle()
                SauronPrimaryButton(title: "Upload", action: selectFiles)
                    .buttonStyle(.plain)

                Text("or drop a project folder here")
                    .font(.custom("IBMPlexMono-Bold", size: 12))
                    .foregroundColor(Brand.accent.opacity(0.8))

                Spacer(minLength: 80)
            }
            .padding(.horizontal, 32)
        }
        .ignoresSafeArea()
        .navigationDestination(isPresented: $showSelection) {
            if let root = selectedRoot {
                PreviewSelectionScreen(root: root, items: detectedItems, tip: tip)
            }
        }
        .overlay(alignment: .center) {
            if isScanning {
                ProgressView("Scanning project...")
                    .padding(16)
                    .background(Color.black.opacity(0.6))
                    .foregroundColor(Brand.accent)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .onDrop(of: [.fileURL], isTargeted: $isDropTarget) { providers in
            guard let provider = providers.first else { return false }
            let typeIdentifier = UTType.fileURL.identifier
            provider.loadItem(forTypeIdentifier: typeIdentifier, options: nil) { item, _ in
                var droppedURL: URL?
                if let url = item as? URL {
                    droppedURL = url
                } else if let data = item as? Data,
                          let str = String(data: data, encoding: .utf8) {
                    let trimmed = str.trimmingCharacters(in: .whitespacesAndNewlines)
                    if let url = URL(string: trimmed) { droppedURL = url }
                }
                if let url = droppedURL, isDirectory(url) {
                    DispatchQueue.main.async {
                        handleSelectedRoot(url)
                    }
                }
            }
            return true
        }
    }

    private func selectFiles() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.allowedContentTypes = [.folder]
        panel.begin { response in
            if response == .OK {
                uploadedURLs = panel.urls
                if let first = panel.urls.first {
                    handleSelectedRoot(first)
                }
            }
        }
    }

    private func handleSelectedRoot(_ root: URL) {
        selectedRoot = root
        isScanning = true
        detectedItems = []
        tip = nil
        let hasAccess = root.startAccessingSecurityScopedResource()
        Task.detached(priority: .userInitiated) {
            let comps = ComposeScanner.detectComponents(at: root)
            let hasPlugin = ComposeScanner.hasComposeScreenshotPlugin(at: root)
            let items = comps.map { component in
                PreviewSelectionItem(
                    name: component.name,
                    filePath: component.filePath,
                    isSelected: false,
                    hasPreview: component.hasPreview,
                    previewAnnotations: component.previewAnnotations
                )
            }
            let tipText: String? = hasPlugin ? nil : "Compose Preview Screenshot Testing setup is missing. Follow https://developer.android.com/studio/preview/compose-screenshot-testing"
            await MainActor.run {
                self.detectedItems = items
                self.tip = tipText
                self.isScanning = false
                self.showSelection = true
            }
            if hasAccess { root.stopAccessingSecurityScopedResource() }
        }
    }

    private func isDirectory(_ url: URL) -> Bool {
        var isDir: ObjCBool = false
        FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir)
        return isDir.boolValue
    }
}

// No local utilities; uses global Brand and Color(hex:)

#Preview {
    UploadScreen()
        .frame(width: 600, height: 420)
}
