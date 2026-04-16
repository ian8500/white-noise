import Foundation

struct AIChatMessage: Identifiable, Equatable, Sendable {
    enum Role: String, Sendable {
        case system
        case user
        case assistant
    }

    let id: UUID
    let role: Role
    let text: String
    let createdAt: Date
    let quickActionChips: [String]

    init(
        id: UUID = UUID(),
        role: Role,
        text: String,
        createdAt: Date = Date(),
        quickActionChips: [String] = []
    ) {
        self.id = id
        self.role = role
        self.text = text
        self.createdAt = createdAt
        self.quickActionChips = quickActionChips
    }
}
