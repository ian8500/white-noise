import Foundation

@MainActor
final class AIChatViewModel: ObservableObject {
    @Published private(set) var messages: [AIChatMessage]
    @Published private(set) var isSending = false
    @Published var composerText = ""

    let context: CopilotContext

    private let service: AIChatService

    init(context: CopilotContext, service: AIChatService = MockAIChatService()) {
        self.context = context
        self.service = service
        self.messages = [
            AIChatMessage(
                role: .assistant,
                text: "I’m here with you. We’ll keep this short and steady.",
                quickActionChips: [
                    "What should I do first?",
                    "Give me the short version",
                    "Help me calm down",
                    "Start a reset"
                ]
            )
        ]
    }

    func sendUserMessage() async {
        let trimmed = composerText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !isSending else { return }

        composerText = ""
        messages.append(AIChatMessage(role: .user, text: trimmed))
        await sendConversation()
    }

    func sendQuickAction(_ action: String) async {
        guard !isSending else { return }
        messages.append(AIChatMessage(role: .user, text: action))
        await sendConversation()
    }

    private func sendConversation() async {
        isSending = true
        defer { isSending = false }

        do {
            let response = try await service.send(messages: messages, context: context)
            messages.append(response)
        } catch {
            messages.append(
                AIChatMessage(
                    role: .assistant,
                    text: "I hit a small issue. For now, take one slow exhale and start a 2-minute reset.",
                    quickActionChips: ["Start a reset", "Give me the short version"]
                )
            )
        }
    }
}
