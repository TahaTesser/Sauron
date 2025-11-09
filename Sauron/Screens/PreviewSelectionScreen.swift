import SwiftUI

// MARK: - Preview Selection Screen
struct PreviewSelectionScreen: View {
    let root: URL
    let directory: String
    @State var items: [PreviewSelectionItem]
    let tip: String?

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
    }

    private func toggleSelectAll() {
        let target = !items.allSatisfy { $0.isSelected }
        for index in items.indices { items[index].isSelected = target }
    }

    private func generate() {
        let selected = items.enumerated().compactMap { idx, it -> ComposeComponent? in
            guard it.isSelected else { return nil }
            return ComposeComponent(
                name: it.name,
                filePath: it.filePath,
                line: 0,
                hasPreview: it.hasPreview,
                previewAnnotations: it.previewAnnotations
            )
        }
        let result = ComposeTestGenerator.generateTests(root: root, components: selected)
        // Basic feedback to console for now; UI notification can be added later.
        if result.created.isEmpty {
            print("Nothing to generate (files already exist) or no previews.")
        } else {
            print("Generated screenshot tests:\n\t" + result.created.joined(separator: "\n\t"))
        }
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
