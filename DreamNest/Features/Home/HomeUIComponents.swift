import SwiftUI

struct HomeLayout {
    static let horizontalPadding: CGFloat = 20
    static let sectionSpacing: CGFloat = 18
    static let cardCornerRadius: CGFloat = 22
    static let minimumTapTarget: CGFloat = 44
    static let topSafeAreaPadding: CGFloat = 18
    static let bottomSafeAreaPadding: CGFloat = 18
    static let headerBottomSpacing: CGFloat = 8
    static let heroBottomSpacing: CGFloat = 8
    static let footerTopSpacing: CGFloat = 12
    static let footerBottomSpacing: CGFloat = 12
    static let footerHorizontalPadding: CGFloat = 14
    static let footerVerticalPadding: CGFloat = 10
    static let footerMaxWidth: CGFloat = 320
}

struct HomeCardModifier: ViewModifier {
    var cornerRadius: CGFloat = HomeLayout.cardCornerRadius
    var opacity: CGFloat = 0.16

    func body(content: Content) -> some View {
        content
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                DreamNestTheme.surface.opacity(opacity + 0.10),
                                DreamNestTheme.surfaceElevated.opacity(opacity + 0.04)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(Color.white.opacity(0.12), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.26), radius: 14, x: 0, y: 8)
    }
}

extension View {
    func homeCard(cornerRadius: CGFloat = HomeLayout.cardCornerRadius, opacity: CGFloat = 0.16) -> some View {
        modifier(HomeCardModifier(cornerRadius: cornerRadius, opacity: opacity))
    }
}

struct MinimumHitTarget: ViewModifier {
    func body(content: Content) -> some View {
        content.frame(minWidth: HomeLayout.minimumTapTarget, minHeight: HomeLayout.minimumTapTarget)
    }
}

extension View {
    func minimumHitTarget() -> some View {
        modifier(MinimumHitTarget())
    }
}

struct CalmScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
            .opacity(configuration.isPressed ? 0.94 : 1)
            .animation(.easeOut(duration: 0.16), value: configuration.isPressed)
    }
}

struct HomeSectionHeader: View {
    let eyebrow: String?
    let title: String
    let subtitle: String?

    init(eyebrow: String? = nil, title: String, subtitle: String? = nil) {
        self.eyebrow = eyebrow
        self.title = title
        self.subtitle = subtitle
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let eyebrow {
                Text(eyebrow.uppercased())
                    .font(.caption.weight(.semibold))
                    .tracking(1.2)
                    .foregroundStyle(DreamNestTheme.tertiaryText)
            }
            Text(title)
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundStyle(DreamNestTheme.primaryText)
            if let subtitle {
                Text(subtitle)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(DreamNestTheme.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct PrimaryActionButton: View {
    let title: String
    let systemImage: String
    var isProminent: Bool = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: systemImage)
                    .font(.system(size: 16, weight: .semibold))
                Text(title)
                    .font(.headline.weight(.semibold))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(
                        isProminent
                            ? LinearGradient(colors: [DreamNestTheme.accentStrong, DreamNestTheme.accent], startPoint: .topLeading, endPoint: .bottomTrailing)
                            : LinearGradient(colors: [DreamNestTheme.surfaceElevated, DreamNestTheme.surface], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color.white.opacity(0.16), lineWidth: 1)
            )
            .shadow(color: isProminent ? DreamNestTheme.accent.opacity(0.35) : .clear, radius: 16, x: 0, y: 8)
        }
        .buttonStyle(CalmScaleButtonStyle())
        .minimumHitTarget()
    }
}

struct SupportCard<Content: View>: View {
    let title: String
    let subtitle: String
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(DreamNestTheme.primaryText)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(DreamNestTheme.secondaryText)
            }
            content()
        }
        .homeCard()
    }
}

struct NightStateCard: View {
    struct Style {
        let icon: String
        let title: String
        let subtitle: String
        let gradient: [Color]
    }

    let style: Style
    var isActive = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 16) {
                Image(systemName: style.icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.94))
                    .padding(11)
                    .background(Circle().fill(Color.white.opacity(0.12)))

                VStack(alignment: .leading, spacing: 4) {
                    Text(style.title)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.white)
                    Text(style.subtitle)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.72))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 148, alignment: .topLeading)
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: style.gradient,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(isActive ? Color.white.opacity(0.6) : Color.white.opacity(0.14), lineWidth: isActive ? 1.5 : 1)
            )
            .shadow(color: .black.opacity(0.24), radius: 12, x: 0, y: 8)
        }
        .buttonStyle(CalmScaleButtonStyle())
    }
}

struct CalmPromptCard: View {
    let text: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "sparkles")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(DreamNestTheme.accentSoft)
            Text(text)
                .font(.footnote.weight(.medium))
                .foregroundStyle(DreamNestTheme.secondaryText)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(DreamNestTheme.surface.opacity(0.8))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }
}
