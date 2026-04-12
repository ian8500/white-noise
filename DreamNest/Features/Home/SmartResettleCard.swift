import SwiftUI

struct SmartResettleCard: View {
    @Binding var isEnabled: Bool
    @Binding var mode: CryComfortMode
    let onToggleChanged: (Bool) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header

            Text("If your little one cries after sound ends, DreamNest can gently replay the same sound to help them settle.")
                .font(.subheadline)
                .foregroundStyle(primaryTextColor)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityLabel("Smart Resettle summary")
                .accessibilityHint("Explains how Smart Resettle helps your baby settle back to sleep")

            modeSelector
                .opacity(isEnabled ? 1 : 0.5)
                .allowsHitTesting(isEnabled)
                .accessibilityElement(children: .contain)

            privacyNote
        }
        .padding(16)
        .background(cardBackground, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(isEnabled ? Color.white.opacity(0.25) : Color.white.opacity(0.12), lineWidth: 1)
        )
        .animation(.easeInOut(duration: 0.22), value: isEnabled)
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Smart Resettle")
                    .font(.headline)
                    .foregroundStyle(.white)
                Text(isEnabled ? "On and ready to comfort" : "Off")
                    .font(.caption)
                    .foregroundStyle(isEnabled ? Color(red: 0.70, green: 0.95, blue: 0.86) : .white.opacity(0.65))
                    .contentTransition(.opacity)
            }

            Spacer(minLength: 8)

            Toggle("Smart Resettle", isOn: Binding(get: { isEnabled }, set: onToggleChanged))
                .labelsHidden()
                .toggleStyle(.switch)
                .tint(Color(red: 0.38, green: 0.73, blue: 0.98))
                .accessibilityLabel("Smart Resettle")
                .accessibilityHint("Turns automatic resettling on or off")
        }
    }

    private var modeSelector: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Comfort style")
                .font(.caption.weight(.semibold))
                .foregroundStyle(primaryTextColor)

            HStack(spacing: 8) {
                ForEach(CryComfortMode.allCases, id: \.self) { option in
                    modeButton(for: option)
                }
            }
            .padding(6)
            .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }

    private func modeButton(for option: CryComfortMode) -> some View {
        let isSelected = mode == option

        return Button {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.86)) {
                mode = option
            }
        } label: {
            Text(option.title)
                .font(.footnote.weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .foregroundStyle(isSelected ? Color.black.opacity(0.78) : primaryTextColor)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(isSelected ? Color.white.opacity(0.95) : Color.clear)
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(option.title)
        .accessibilityHint(accessibilityHint(for: option))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var privacyNote: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "lock.shield")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.65))
                .padding(.top, 1)

            Text("Privacy-safe by design: cry checks happen on your device, and history stays on this phone.")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.62))
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Privacy-safe by design. Cry checks happen on your device, and history stays on this phone.")
    }

    private var cardBackground: some ShapeStyle {
        isEnabled
            ? LinearGradient(
                colors: [
                    Color(red: 0.16, green: 0.27, blue: 0.45).opacity(0.88),
                    Color(red: 0.11, green: 0.16, blue: 0.28).opacity(0.88)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            : LinearGradient(
                colors: [Color.white.opacity(0.12), Color.white.opacity(0.08)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
    }

    private var primaryTextColor: Color {
        isEnabled ? .white.opacity(0.92) : .white.opacity(0.72)
    }

    private func accessibilityHint(for option: CryComfortMode) -> String {
        switch option {
        case .gentle:
            return "Reacts only to clearer cries for fewer replays"
        case .balanced:
            return "A middle option for most families"
        case .responsive:
            return "Responds sooner for quick comfort"
        }
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        SmartResettleCard(
            isEnabled: .constant(true),
            mode: .constant(.balanced),
            onToggleChanged: { _ in }
        )
        .padding()
    }
}
