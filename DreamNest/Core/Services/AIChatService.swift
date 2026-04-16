import Foundation

protocol AIChatService {
    func send(messages: [AIChatMessage], context: CopilotContext) async throws -> AIChatMessage
}

struct MockAIChatService: AIChatService {
    private let promptBuilder: PromptBuilder
    private let safetyEscalationService: SafetyEscalationService

    init(
        promptBuilder: PromptBuilder = PromptBuilder(),
        safetyEscalationService: SafetyEscalationService = SafetyEscalationService()
    ) {
        self.promptBuilder = promptBuilder
        self.safetyEscalationService = safetyEscalationService
    }

    func send(messages: [AIChatMessage], context: CopilotContext) async throws -> AIChatMessage {
        let _ = promptBuilder.makeSystemPrompt(context: context)

        if let last = messages.last(where: { $0.role == .user }),
           let escalation = safetyEscalationService.escalationMessageIfNeeded(for: last.text) {
            return AIChatMessage(
                role: .assistant,
                text: escalation,
                quickActionChips: ["Start a reset", "Give me the short version"]
            )
        }

        let stateLine: String
        switch context.entryPoint {
        case .nightState:
            stateLine = "You're doing the right thing by pausing for a moment."
        case .helpNow:
            stateLine = "You're not alone right now; we can keep this very simple."
        case .resetCompletion:
            stateLine = "You got through that reset, and that still counts as progress."
        case .tonightAnchor:
            stateLine = "Let's stay gentle and anchor to one clear next move."
        }

        let timerLine = context.timerMinutes.map { "Set a \($0)-minute timer and let your body follow it." }
            ?? "Set a short timer so your brain has an endpoint."

        let message = """
        \(stateLine)
        \(timerLine)
        • Keep your jaw loose and exhale slightly longer than you inhale.
        • Dim the screen and pick one quiet sound for the next few minutes.
        • If your thoughts race, name one thought and set it aside until morning.
        """

        return AIChatMessage(
            role: .assistant,
            text: message,
            quickActionChips: [
                "What should I do first?",
                "Give me the short version",
                "What if that doesn’t work?",
                "Help me calm down",
                "Start a reset"
            ]
        )
    }
}
