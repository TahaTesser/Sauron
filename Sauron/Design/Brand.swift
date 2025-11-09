import SwiftUI

// Global design tokens for colors and helpers
enum Brand {
    static let background = Color(hex: 0x0D0D0D)
    static let accent = Color(hex: 0xFFB100)
}
// Shared hex color convenience
extension Color {
    init(hex: UInt32, alpha: Double = 1.0) {
        let r = Double((hex >> 16) & 0xFF) / 255.0
        let g = Double((hex >> 8) & 0xFF) / 255.0
        let b = Double(hex & 0xFF) / 255.0
        self = Color(red: r, green: g, blue: b, opacity: alpha)
    }
}
