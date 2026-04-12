import SwiftUI

struct PresetCard: View {
    struct State: OptionSet {
        let rawValue: Int

        static let selected = State(rawValue: 1 << 0)
        static let pinned = State(rawValue: 1 << 1)
        static let active = State(rawValue: 1 << 2)
    }

    let title: String
    let icon: String
    let soundTitle: String
    let metadata: String
    let state: State
    let onTap: () -> Void
    let onLongPress: () -> Void

    private var isPinned: Bool { state.contains(.pinned) }
    private var isActive: Bool { state.contains(.active) }
    private var isSelected: Bool { state.contains(.selected) || isActive }

    private var cardFill: LinearGradient {
        let top = isSelected ? Color.white.opacity(0.2) : Color.white.opacity(0.14)
        let bottom = isSelected ? Color.white.opacity(0.1) : Color.white.opacity(0.06)
        return LinearGradient(colors: [top, bottom], startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    private var strokeColor: Color {
        if isActive { return Color(hex: "9BC4FF").opacity(0.8) }
        if isPinned { return Color(hex: "E4A890").opacity(0.75) }
        if isSelected { return Color.white.opacity(0.48) }
        return Color.white.opacity(0.22)
    }

    private var glowColor: Color {
        if isActive { return Color(hex: "9BC4FF").opacity(0.35) }
        if isPinned { return Color(hex: "E4A890").opacity(0.27) }
        return .white.opacity(isSelected ? 0.12 : 0.05)
    }

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top, spacing: 10) {
                    Label(title, systemImage: icon)
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                    Spacer(minLength: 8)
                    pinBadge
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text(soundTitle)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.95))
                        .lineLimit(1)

                    HStack(spacing: 6) {
                        Image(systemName: "slider.horizontal.3")
                            .font(.caption.weight(.bold))
                        Text(metadata)
                            .font(.system(.caption, design: .rounded).weight(.medium))
                            .monospacedDigit()
                    }
                    .foregroundStyle(.white.opacity(0.78))
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, minHeight: 118, alignment: .leading)
            .background(cardFill, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .background(.ultraThinMaterial.opacity(0.23), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(strokeColor, lineWidth: isSelected ? 1.2 : 1)
            )
            .shadow(color: glowColor, radius: isSelected ? 16 : 10, y: isSelected ? 8 : 5)
        }
        .buttonStyle(PresetCardButtonStyle())
        .simultaneousGesture(LongPressGesture(minimumDuration: 0.45).onEnded { _ in onLongPress() })
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(title), \(soundTitle), \(metadata)\(isPinned ? ", pinned" : "")\(isActive ? ", active" : "")")
        .accessibilityHint("Double tap to start this preset. Long press to edit.")
        .animation(.spring(response: 0.28, dampingFraction: 0.86), value: state)
    }

    @ViewBuilder
    private var pinBadge: some View {
        Image(systemName: isPinned ? "pin.fill" : "pin")
            .font(.system(size: 12, weight: .bold))
            .foregroundStyle(isPinned ? Color(hex: "E4A890") : .white.opacity(0.5))
            .padding(8)
            .background(
                Circle()
                    .fill((isPinned ? Color(hex: "E4A890") : .white).opacity(isPinned ? 0.18 : 0.1))
            )
            .overlay(
                Circle()
                    .stroke((isPinned ? Color(hex: "E4A890") : .white).opacity(isPinned ? 0.45 : 0.2), lineWidth: 1)
            )
            .accessibilityHidden(true)
    }
}

private struct PresetCardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
            .brightness(configuration.isPressed ? 0.025 : 0)
            .animation(.easeOut(duration: 0.16), value: configuration.isPressed)
    }
}

private extension Color {
    init(hex: String) {
        let cleaned = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&int)
        let r, g, b: UInt64
        switch cleaned.count {
        case 6: (r, g, b) = (int >> 16, int >> 8 & 0xFF, int & 0xFF)
        default: (r, g, b) = (245, 247, 250)
        }
        self.init(.sRGB, red: Double(r)/255, green: Double(g)/255, blue: Double(b)/255, opacity: 1)
    }
}
