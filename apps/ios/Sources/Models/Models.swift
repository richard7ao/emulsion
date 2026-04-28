import Foundation

struct Portfolio: Codable, Identifiable {
    let id: Int
    let name: String
    let bio: String
    let photoPath: String?
    let summary: String
    let createdAt: String
}

struct Experience: Codable, Identifiable {
    let id: Int
    let portfolioId: Int
    let company: String
    let role: String
    let dates: String
    let bullets: String
}

struct Skill: Codable, Identifiable {
    let id: Int
    let portfolioId: Int
    let category: String
    let items: String
}

struct Project: Codable, Identifiable {
    let id: Int
    let portfolioId: Int
    let title: String
    let role: String
    let writeup: String
    let screenshots: String
    let viewCount: Int
    let interestedCount: Int
}

struct QAPair: Codable, Identifiable {
    let id: Int
    let portfolioId: Int
    let prompt: String
    let answer: String
    let isCanned: Bool
}

struct Note: Codable, Identifiable {
    let id: Int
    let portfolioId: Int
    let name: String
    let email: String
    let message: String
    let createdAt: String
}

struct Conversation: Codable, Identifiable {
    let id: Int
    let portfolioId: Int
    let participantName: String
    let lastMessage: String
    let updatedAt: String
}

struct Message: Codable, Identifiable {
    let id: Int
    let conversationId: Int
    let sender: String
    let body: String
    let createdAt: String
}

struct PortfolioResponse: Codable {
    let portfolio: Portfolio
    let experiences: [Experience]
    let skills: [Skill]
}

struct AskMatch: Codable {
    let prompt: String
    let answer: String
}

struct AskResponse: Codable {
    let match: AskMatch?
    let fallback: String?
}

struct ConversationsResponse: Codable {
    let conversations: [Conversation]
    let theatre: Bool
}

struct MessagesResponse: Codable {
    let messages: [Message]
    let theatre: Bool
}

struct CreateNoteRequest: Codable {
    let name: String
    let email: String
    let message: String
}

struct CreateNoteResponse: Codable {
    let id: Int
}

struct InterestedResponse: Codable {
    let status: String
}
