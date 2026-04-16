import Foundation

struct SafetyEscalationService {
    private let highRiskKeywords: [String] = [
        "self harm", "hurt myself", "kill myself", "suicide", "suicidal",
        "can't breathe", "cannot breathe", "breathing", "chest pain",
        "danger", "unsafe", "overdose", "emergency", "urgent symptom"
    ]

    func escalationMessageIfNeeded(for userText: String) -> String? {
        let normalized = userText.lowercased()
        let isHighRisk = highRiskKeywords.contains(where: { normalized.contains($0) })
        guard isHighRisk else { return nil }

        return """
        I’m really glad you said this.
        Please call emergency services right now (911 in the U.S.) and contact a trusted person nearby immediately.
        If you can, unlock your door and stay where help can reach you quickly.
        """
    }
}
