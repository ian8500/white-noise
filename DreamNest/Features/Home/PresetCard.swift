import SwiftUI

struct PresetCard: View {
    struct State: OptionSet {
        let rawValue: Int

        static let selected = State(rawValue: 1 << 0)
        static let active = State(rawValue: 1 << 1)
    }

    let title: String
    let icon: String
    let soundTitle: String
    let metadata: String
    let state: State
    let onTap: () -> Void
    let onLongPress: () -> Void

    private var isActive: Bool { state.contains(.active) }
    private var isSelected: Bool { state.contains(.selected) || isActive }

    private var cardFill: LinearGradient {
        let top = isSelected ? Color.white.opacity(0.21) : Color.white.opacity(0.15)
        let bottom = isSelected ? Color.white.opacity(0.11) : Color.white.opacity(0.07)
        return LinearGradient(colors: [top, bottom], startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    private var strokeColor: Color {
        if isActive { return Color.white.opacity(0.52) }
        if isSelected { return Color.white.opacity(0.4) }
        return Color.white.opacity(0.24)
    }

    private var shadowColor: Color {
        if isActive { return .white.opacity(0.17) }
        if isSelected { return .white.opacity(0.11) }
        return .black.opacity(0.14)
    }

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                Label(title, systemImage: icon)
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)

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
            .presetCardSurface(
                fill: cardFill,
                stroke: strokeColor,
                shadow: shadowColor,
                isSelected: isSelected
            )
        }
        .buttonStyle(PresetCardButtonStyle())
        .simultaneousGesture(LongPressGesture(minimumDuration: 0.45).onEnded { _ in onLongPress() })
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(title), \(soundTitle), \(metadata)\(isActive ? ", active" : "")")
        .accessibilityHint("Double tap to start this preset. Long press to edit.")
        .animation(.spring(response: 0.28, dampingFraction: 0.86), value: state)
    }
}

private struct PresetCardSurfaceModifier: ViewModifier {
    let fill: LinearGradient
    let stroke: Color
    let shadow: Color
    let isSelected: Bool

    func body(content: Content) -> some View {
        content
            .background(fill, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .background(.ultraThinMaterial.opacity(0.23), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(stroke, lineWidth: isSelected ? 1.2 : 1)
            )
            .shadow(color: shadow, radius: isSelected ? 16 : 10, y: isSelected ? 8 : 5)
    }
}

private extension View {
    func presetCardSurface(fill: LinearGradient, stroke: Color, shadow: Color, isSelected: Bool) -> some View {
        modifier(PresetCardSurfaceModifier(fill: fill, stroke: stroke, shadow: shadow, isSelected: isSelected))
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
