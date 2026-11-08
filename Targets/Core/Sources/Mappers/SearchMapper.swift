import Foundation

public extension MessageSearchHitDTO {
    func toDomain() -> MessageSearchHit {
        MessageSearchHit(message: message.toDomain(), conversationId: message.conversationId, conversationTitle: conversationTitle)
    }
}

public extension GlobalSearchResultsDTO {
    func toDomain() -> GlobalSearchResults {
        GlobalSearchResults(
            conversations: conversations.map { $0.toDomain() },
            messages: messages.map { $0.toDomain() },
            users: users.map { $0.toDomain() }
        )
    }
}
