import SwiftUI

enum DreamNestTheme {
    static let background = LinearGradient(
        colors: [Color(red: 0.06, green: 0.07, blue: 0.15), Color(red: 0.13, green: 0.1, blue: 0.2)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let cardBackground = Color.white.opacity(0.07)
    static let modalBackground = Color(red: 0.10, green: 0.11, blue: 0.19)
    static let elevatedControlBackground = Color(red: 0.15, green: 0.16, blue: 0.26)
    static let primaryText = Color.white
    static let secondaryText = Color.white.opacity(0.75)
    static let accent = Color(red: 0.62, green: 0.58, blue: 0.98)
}
