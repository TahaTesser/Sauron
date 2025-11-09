import Foundation

struct PreviewSelectionItem: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let filePath: String
    var isSelected: Bool = false
    var hasPreview: Bool = false
    var previewAnnotations: [String] = []

    init(name: String, filePath: String, isSelected: Bool = false, hasPreview: Bool = false, previewAnnotations: [String] = []) {
        self.name = name
        self.filePath = filePath
        self.isSelected = isSelected
        self.hasPreview = hasPreview
        self.previewAnnotations = previewAnnotations
    }
}
