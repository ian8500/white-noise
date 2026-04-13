import SwiftUI

struct HomeLayout {
    static let horizontalPadding: CGFloat = 20
    static let sectionSpacing: CGFloat = 16
    static let cardCornerRadius: CGFloat = 20
    static let minimumTapTarget: CGFloat = 44
    static let topSafeAreaPadding: CGFloat = 18
    static let bottomSafeAreaPadding: CGFloat = 18
    static let headerBottomSpacing: CGFloat = 4
    static let heroBottomSpacing: CGFloat = 4
    static let footerTopSpacing: CGFloat = 10
    static let footerBottomSpacing: CGFloat = 8
    static let footerHorizontalPadding: CGFloat = 14
    static let footerVerticalPadding: CGFloat = 10
    static let footerMaxWidth: CGFloat = 320
}

struct HomeCardModifier: ViewModifier {
    var cornerRadius: CGFloat = HomeLayout.cardCornerRadius
    var opacity: CGFloat = 0.2

    func body(content: Content) -> some View {
        content
            .padding(16)
            .background(.ultraThinMaterial.opacity(opacity), in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
    }
}

extension View {
    func homeCard(cornerRadius: CGFloat = HomeLayout.cardCornerRadius, opacity: CGFloat = 0.2) -> some View {
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
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .opacity(configuration.isPressed ? 0.92 : 1)
            .animation(.easeOut(duration: 0.16), value: configuration.isPressed)
    }
}
