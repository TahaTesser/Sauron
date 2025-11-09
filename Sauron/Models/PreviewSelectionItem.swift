import Foundation

struct PreviewSelectionItem: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let filePath: String
    var isSelected: Bool = false

    init(name: String, filePath: String, isSelected: Bool = false) {
        self.name = name
        self.filePath = filePath
        self.isSelected = isSelected
    }
}
