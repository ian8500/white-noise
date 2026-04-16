import SwiftUI

enum DreamNestTheme {
    static let background = LinearGradient(
        colors: [
            Color(hex: "080B14"),
            Color(hex: "111A2A"),
            Color(hex: "171E32")
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let surface = Color(hex: "1B2438")
    static let surfaceElevated = Color(hex: "232F46")
    static let cardBackground = Color.white.opacity(0.07)
    static let modalBackground = Color(hex: "141C2B")
    static let elevatedControlBackground = Color(hex: "2A3550")

    static let primaryText = Color.white
    static let secondaryText = Color.white.opacity(0.76)
    static let tertiaryText = Color.white.opacity(0.56)

    static let accent = Color(hex: "7185C7")
    static let accentStrong = Color(hex: "5D73B8")
    static let accentSoft = Color(hex: "A3B7EA")
}

private extension Color {
    init(hex: String) {
        let cleaned = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&int)
        let r, g, b: UInt64
        switch cleaned.count {
        case 6:
            (r, g, b) = (int >> 16, int >> 8 & 0xFF, int & 0xFF)
        default:
            (r, g, b) = (245, 247, 250)
        }
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: 1)
    }
}
