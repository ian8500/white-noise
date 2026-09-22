import SwiftUI

enum DreamNestTheme {
    static let background = LinearGradient(
        colors: [
            Color(hex: "0B1014"),
            Color(hex: "11181D"),
            Color(hex: "171B1D")
        ],
        startPoint: .top,
        endPoint: .bottom
    )

    static let surface = Color(hex: "1C2428")
    static let surfaceElevated = Color(hex: "263035")
    static let cardBackground = Color(hex: "1C2428")
    static let modalBackground = Color(hex: "11181D")
    static let elevatedControlBackground = Color(hex: "263035")

    static let primaryText = Color(hex: "F5F0E8")
    static let secondaryText = Color(hex: "C9C2B8")
    static let tertiaryText = Color(hex: "918A82")

    static let accent = Color(hex: "C79A62")
    static let accentStrong = Color(hex: "AD7E49")
    static let accentSoft = Color(hex: "E6D0B2")
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
