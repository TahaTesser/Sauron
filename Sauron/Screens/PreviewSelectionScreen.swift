import SwiftUI

// MARK: - Preview Selection Screen
struct PreviewSelectionScreen: View {
    let root: URL
    let directory: String
    @State var items: [PreviewSelectionItem]
    let tip: String?
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    @State private var hasSecurityAccess: Bool = false
    @State private var navigateToResults: Bool = false
    @State private var selectedComponents: [ComposeComponent] = []

    init(root: URL, items: [PreviewSelectionItem], tip: String?) {
        self.root = root
        self.directory = root.lastPathComponent
        self._items = State(initialValue: items)
        self.tip = tip
    }

    var body: some View {
        ZStack {
            Brand.background

            VStack(spacing: 28) {
                // Title centered
                HStack {
                    Spacer()
                    SauronTitle()
                    Spacer()
                }
                .padding(.top, 8)

                // Content left-aligned
                VStack(alignment: .leading, spacing: 18) {
                    Text("Detected the following @Composable previews in \(directory) to generate screenshot tests")
                        .font(.custom("IBMPlexMono-Bold", size: 14))
                        .foregroundColor(Brand.accent)

                    ForEach(items.indices, id: \.self) { index in
                        PreviewRow(item: $items[index])
                    }

                    Button(action: toggleSelectAll, label: {
                        Text("\(items.allSatisfy { $0.isSelected } ? "[x]" : "[ ]")  Select all")
                            .font(.custom("IBMPlexMono-Bold", size: 14))
                            .foregroundColor(Brand.accent)
                    })
                    .buttonStyle(.plain)

                    Text("Tip: \(tip?.isEmpty == false ? tip! : "<placeholder>")")
                        .font(.custom("IBMPlexMono-Bold", size: 14))
                        .foregroundColor(Brand.accent)
                        .padding(.top, 8)

                    SauronPrimaryButton(title: "Generate Tests", action: generate)
                        .buttonStyle(.plain)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 24)
        }
        .ignoresSafeArea()
        .alert("Test Generation", isPresented: $showAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
        .onAppear {
            hasSecurityAccess = root.startAccessingSecurityScopedResource()
            print("[PreviewSelectionScreen] Security access started: \(hasSecurityAccess)")
        }
        .onDisappear {
            if hasSecurityAccess {
                root.stopAccessingSecurityScopedResource()
                print("[PreviewSelectionScreen] Security access stopped")
            }
        }
        .navigationDestination(isPresented: $navigateToResults) {
            GenerationResultScreen(root: root, components: selectedComponents)
        }
    }

    private func toggleSelectAll() {
        let target = !items.allSatisfy { $0.isSelected }
        for index in items.indices { items[index].isSelected = target }
    }

    private func generate() {
        let selected = items.compactMap { it -> ComposeComponent? in
            guard it.isSelected else { return nil }
            return ComposeComponent(
                name: it.name,
                filePath: it.filePath,
                line: 0,
                hasPreview: it.hasPreview,
                previewAnnotations: it.previewAnnotations
            )
        }

        guard !selected.isEmpty else {
            alertMessage = "Please select at least one preview to generate tests."
            showAlert = true
            return
        }

        selectedComponents = selected
        navigateToResults = true
    }
}
// MARK: - Row component
private struct PreviewRow: View {
    @Binding var item: PreviewSelectionItem
    var body: some View {
        Button(action: { item.isSelected.toggle() }, label: {
            VStack(alignment: .leading, spacing: 6) {
                Text("\(item.isSelected ? "[x]" : "[ ]")  \(item.name)")
                    .font(.custom("IBMPlexMono-Bold", size: 14))
                    .foregroundColor(Brand.accent)
                Text("    \(item.filePath)")
                    .font(.custom("IBMPlexMono-Bold", size: 14))
                    .foregroundColor(Brand.accent)
            }
        })
        .buttonStyle(.plain)
    }
}

// Uses global Brand and Color(hex:)

#Preview {
    // Ensure fonts are available during previews
    FontLoader.registerBundledFonts()
    let demo = [
        PreviewSelectionItem(name: "Preview Name", filePath: "file_path.kt"),
        PreviewSelectionItem(name: "Preview Name", filePath: "file_path.kt"),
        PreviewSelectionItem(name: "Preview Name", filePath: "file_path.kt")
    ]
    return PreviewSelectionScreen(root: URL(fileURLWithPath: "/path/to/project"), items: demo, tip: "<placeholder>")
        .frame(width: 800, height: 600)
}
