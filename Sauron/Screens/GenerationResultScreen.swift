import SwiftUI
import Foundation

struct GenerationResultScreen: View {
    let root: URL
    let components: [ComposeComponent]

    @State private var isGenerating: Bool = true
    @State private var createdPaths: [String] = []
    @State private var generationMessage: String = ""

    var body: some View {
        ZStack {
            Brand.background

            VStack(spacing: 24) {
                HStack {
                    Spacer()
                    SauronTitle()
                    Spacer()
                }
                .padding(.top, 8)

                VStack(alignment: .leading, spacing: 16) {
                    Text("Generating screenshot tests...")
                        .font(.custom("IBMPlexMono-Bold", size: 14))
                        .foregroundColor(Brand.accent)

                    if isGenerating {
                        ProgressView("Generating tests...")
                            .padding(.vertical, 8)
                    }

                    if !createdPaths.isEmpty {
                        Text("Generated tests:")
                            .font(.custom("IBMPlexMono-Bold", size: 14))
                            .foregroundColor(Brand.accent)

                        ScrollView {
                            VStack(alignment: .leading, spacing: 6) {
                                ForEach(createdPaths, id: \.self) { path in
                                    Text(path)
                                        .font(.custom("IBMPlexMono-Bold", size: 12))
                                        .foregroundColor(Brand.accent)
                                }
                            }
                        }
                        .frame(maxHeight: 160)
                    }

                    if !generationMessage.isEmpty {
                        Text(generationMessage)
                            .font(.custom("IBMPlexMono-Bold", size: 12))
                            .foregroundColor(Brand.accent)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 24)
        }
        .ignoresSafeArea()
        .onAppear { startGeneration() }
    }

    private func startGeneration() {
        guard isGenerating else { return }
        Task.detached(priority: .userInitiated) {
            let result = ComposeTestGenerator.generateTests(root: root, components: components)
            await MainActor.run {
                self.createdPaths = result.created
                self.isGenerating = false

                if result.created.isEmpty {
                    self.generationMessage = "Selected screenshot test(s) already exist or nothing new was generated."
                } else {
                    let count = result.created.count
                    self.generationMessage = "Generated \(count) screenshot test\(count == 1 ? "" : "s")."
                }
            }
        }
    }
}

#Preview {
    GenerationResultScreen(
        root: URL(fileURLWithPath: "/path/to/project"),
        components: []
    )
    .frame(width: 800, height: 600)
}
