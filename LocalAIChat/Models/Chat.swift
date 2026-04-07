import Foundation

struct Chat: Identifiable, Equatable, Codable {
    let id: UUID
    var title: String
    var messages: [Message]
    let createdAt: Date
    var updatedAt: Date

    init(id: UUID = UUID(), title: String = "New Chat", messages: [Message] = [], createdAt: Date = Date(), updatedAt: Date = Date()) {
        self.id = id
        self.title = title
        self.messages = messages
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    static func == (lhs: Chat, rhs: Chat) -> Bool {
        lhs.id == rhs.id
    }

    var displayTitle: String {
        if title == "New Chat" && !messages.isEmpty {
            let firstUserMessage = messages.first { $0.role == "user" }
            if let content = firstUserMessage?.content {
                let trimmed = content.prefix(50).trimmingCharacters(in: .whitespacesAndNewlines)
                return trimmed.count < content.count ? "\(trimmed)..." : trimmed
            }
        }
        return title
    }
}