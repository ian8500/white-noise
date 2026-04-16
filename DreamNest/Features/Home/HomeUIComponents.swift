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

struct TimerControlCard: View {
    let timeText: String
    let selectedPresetMinutes: Int?
    let quickPresets: [Int]
    let onAdjust: (Int) -> Void
    let onSelectPreset: (Int) -> Void
    private let adjustments = [-10, -5, -1, 1, 5, 10]
    private let columns = [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)]

    var body: some View {
        VStack(spacing: 14) {
            adjustmentSection
            timerDisplay
            presetSection
        }
        .padding(16)
        .background(.ultraThinMaterial.opacity(0.25), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private var adjustmentSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Adjustments")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white.opacity(0.68))
            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(adjustments, id: \.self) { delta in
                    TimerPillButton(title: delta > 0 ? "+\(delta)" : "\(delta)") {
                        onAdjust(delta)
                    }
                }
            }
        }
    }

    private var timerDisplay: some View {
        VStack(spacing: 6) {
            Text("Sleep Timer")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white.opacity(0.68))
            Text(timeText)
                .font(.system(size: 40, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .contentTransition(.numericText())
                .animation(.spring(duration: 0.25, bounce: 0.18), value: timeText)
        }
        .padding(.vertical, 8)
    }

    private var presetSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Presets")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white.opacity(0.68))
            HStack(spacing: 10) {
                ForEach(quickPresets, id: \.self) { preset in
                    TimerPillButton(title: presetTitle(for: preset), isSelected: selectedPresetMinutes == preset) {
                        onSelectPreset(preset)
                    }
                }
            }
        }
    }

    private func presetTitle(for minutes: Int) -> String {
        switch minutes {
        case 60: return "1h"
        case 120: return "2h"
        default: return "\(minutes)m"
        }
    }
}

private struct TimerPillButton: View {
    let title: String
    var isSelected = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.92)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .foregroundStyle(.white)
                .background(Capsule().fill(isSelected ? Color.white.opacity(0.28) : Color.white.opacity(0.12)))
                .overlay(Capsule().stroke(isSelected ? Color.white.opacity(0.85) : Color.white.opacity(0.2), lineWidth: 1))
        }
        .buttonStyle(.plain)
        .frame(minHeight: 44)
    }
}

struct SoundSelectionSummaryView: View {
    let sound: SoundDefinition
    let isPlaying: Bool
    let tapAction: () -> Void
    let longPressAction: () -> Void

    var body: some View {
        SoundPressableTile(tapAction: tapAction, longPressAction: longPressAction) {
            HStack(spacing: 12) {
                let style = SoundVisualStyle.forSound(sound)
                Image(systemName: style.icon)
                    .font(.system(size: 18, weight: .semibold))
                    .padding(10)
                    .background(RoundedRectangle(cornerRadius: 12).fill(style.primary.opacity(0.24)))

                VStack(alignment: .leading, spacing: 3) {
                    Text(style.title).font(.headline)
                    Text(style.subtitle)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.72))
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.7))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, alignment: .leading)
            .homeCard(opacity: 0.24)
        }
    }
}

struct SoundPickerSheet: View {
    let sounds: [SoundDefinition]
    let selectedSoundID: String
    let title: String
    let applyButtonTitle: String
    let isSoundUnlocked: (SoundDefinition) -> Bool
    let onSelect: (SoundDefinition) -> Void
    let onLockedSelect: (SoundDefinition) -> Void
    let onApply: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(sounds, id: \.id) { sound in
                        SoundTileView(
                            sound: sound,
                            isSelected: selectedSoundID == sound.id,
                            isLocked: !isSoundUnlocked(sound)
                        ) {
                            if isSoundUnlocked(sound) {
                                onSelect(sound)
                            } else {
                                onLockedSelect(sound)
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle(title)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { Button("Close") { dismiss() } }
                ToolbarItem(placement: .topBarTrailing) { Button(applyButtonTitle) { onApply(); dismiss() } }
            }
        }
    }
}

private struct SoundTileView: View {
    let sound: SoundDefinition
    let isSelected: Bool
    let isLocked: Bool
    let action: () -> Void

    var body: some View {
        let style = SoundVisualStyle.forSound(sound)
        return Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .top) {
                    Image(systemName: style.icon).font(.title2)
                    Spacer()
                    if isLocked {
                        Image(systemName: "lock.fill")
                            .font(.caption.weight(.semibold))
                            .padding(6)
                            .background(Circle().fill(Color.white.opacity(0.16)))
                    }
                }
                Text(style.title).font(.headline)
                Text(isLocked ? "Premium calm theme" : style.subtitle).font(.caption)
            }
            .foregroundStyle(.white)
            .padding(12)
            .frame(maxWidth: .infinity, minHeight: 120, alignment: .leading)
            .background(style.background.opacity(0.5), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(
                        isSelected ? style.primary : (isLocked ? Color.white.opacity(0.24) : Color.white.opacity(0.14)),
                        lineWidth: isSelected ? 1.2 : 1
                    )
            )
        }
        .buttonStyle(CalmScaleButtonStyle())
        .opacity(isLocked ? 0.88 : 1)
    }
}

private struct SoundPressableTile<Content: View>: View {
    let tapAction: () -> Void
    let longPressAction: () -> Void
    var longPressDuration: Double = 0.5
    @ViewBuilder let content: () -> Content

    var body: some View {
        Button(action: tapAction) {
            content()
        }
        .buttonStyle(CalmScaleButtonStyle())
        .simultaneousGesture(LongPressGesture(minimumDuration: longPressDuration).onEnded { _ in longPressAction() })
    }
}

private struct SoundVisualStyle {
    let icon: String
    let title: String
    let subtitle: String
    let primary: Color
    let background: Color

    static func forSound(_ sound: SoundDefinition) -> SoundVisualStyle {
        let id = sound.id.lowercased()
        if id.contains("rain") { return .init(icon: "cloud.rain.fill", title: "Rain", subtitle: "Soft rainfall", primary: Color(hex: "9AB4D8"), background: Color(hex: "354A62")) }
        if id.contains("white") { return .init(icon: "waveform", title: "White Noise", subtitle: "Airy masking hush", primary: Color(hex: "D4DFEA"), background: Color(hex: "4A5363")) }
        if id.contains("pink") { return .init(icon: "waveform.path.ecg", title: sound.title, subtitle: "Warm blanket noise", primary: Color(hex: "E0B7C0"), background: Color(hex: "5A3F53")) }
        if id.contains("fire") { return .init(icon: "flame.fill", title: "Fire", subtitle: "Cozy ember crackle", primary: Color(hex: "E4A890"), background: Color(hex: "5B4138")) }
        return .init(icon: "sparkles", title: sound.title, subtitle: "Calm ambience", primary: Color(hex: "B4BDD3"), background: Color(hex: "39435A"))
    }
}

struct SessionStatusCard: View {
    enum Tone {
        case idle
        case active
        case monitoring
        case attention
    }

    let title: String
    let detail: String
    let tone: Tone
    let onOpenRecentEvents: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                Text(detail)
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(.white.opacity(0.76))
                    .lineLimit(2)
            }

            Spacer(minLength: 8)

            Button(action: onOpenRecentEvents) {
                VStack(spacing: 4) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 15, weight: .semibold))
                    Text("Recent")
                        .font(.caption2.weight(.semibold))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 9)
                .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Color.white.opacity(0.12)))
                .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(Color.white.opacity(0.16), lineWidth: 1))
            }
            .minimumHitTarget()
            .buttonStyle(CalmScaleButtonStyle())
        }
        .padding(.horizontal, 15)
        .padding(.vertical, 13)
        .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(backgroundColor))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(borderColor, lineWidth: 1))
    }

    private var backgroundColor: Color {
        switch tone {
        case .idle:
            return Color(hex: "9BC4FF").opacity(0.13)
        case .active:
            return Color(hex: "7E9DE8").opacity(0.16)
        case .monitoring:
            return Color(hex: "9FB7FF").opacity(0.2)
        case .attention:
            return Color(hex: "E4A890").opacity(0.2)
        }
    }

    private var borderColor: Color {
        switch tone {
        case .attention:
            return Color(hex: "F1D2BF").opacity(0.45)
        default:
            return Color.white.opacity(0.15)
        }
    }
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
