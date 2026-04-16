import SwiftUI

struct AIChatView: View {
    @StateObject var viewModel: AIChatViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "091322"), Color(hex: "121E34"), Color(hex: "1A2742")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 14) {
                header

                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.messages) { message in
                            messageBubble(message)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                }

                composer
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text("Ask Copilot")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.white)
                Text("Bounded support for night-time moments")
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.72))
            }
            Spacer()
            Button("Close") { dismiss() }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Capsule().fill(Color.white.opacity(0.14)))
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
    }

    private func messageBubble(_ message: AIChatMessage) -> some View {
        VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 10) {
            Text(message.text)
                .font(.body.weight(.medium))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, alignment: message.role == .user ? .trailing : .leading)
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(message.role == .user ? Color(hex: "2D5B95") : Color.white.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .stroke(Color.white.opacity(message.role == .user ? 0.22 : 0.14), lineWidth: 1)
                        )
                )

            if message.role == .assistant, !message.quickActionChips.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(message.quickActionChips, id: \.self) { chip in
                            Button(chip) {
                                Task { await viewModel.sendQuickAction(chip) }
                            }
                            .buttonStyle(.plain)
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(Capsule().fill(Color.white.opacity(0.12)))
                            .overlay(Capsule().stroke(Color.white.opacity(0.14), lineWidth: 1))
                            .contentShape(Capsule())
                        }
                    }
                    .padding(.horizontal, 2)
                }
            }
        }
    }

    private var composer: some View {
        HStack(spacing: 10) {
            TextField("Share what feels hardest right now", text: $viewModel.composerText, axis: .vertical)
                .lineLimit(1 ... 3)
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(RoundedRectangle(cornerRadius: 16).fill(Color.white.opacity(0.1)))
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.12), lineWidth: 1))
                .foregroundStyle(.white)

            Button {
                Task { await viewModel.sendUserMessage() }
            } label: {
                Image(systemName: viewModel.isSending ? "hourglass" : "paperplane.fill")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(width: 48, height: 48)
                    .background(Circle().fill(DreamNestTheme.accent))
            }
            .disabled(viewModel.isSending)
        }
    }
}

#Preview {
    AIChatView(
        viewModel: AIChatViewModel(
            context: .init(entryPoint: .helpNow, nightState: "Feeling overwhelmed", timerMinutes: 2, isLowStimulationMode: true)
        )
    )
}
