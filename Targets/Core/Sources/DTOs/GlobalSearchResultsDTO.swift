import Foundation

/// A matching message plus its conversation's title, so a result can be shown without a second lookup.
public struct MessageSearchHitDTO: Codable, Sendable {
    public let message: MessageDTO
    public let conversationTitle: String

    public init(message: MessageDTO, conversationTitle: String) {
        self.message = message
        self.conversationTitle = conversationTitle
    }
}

/// Wire-format response of the global search endpoint.
public struct GlobalSearchResultsDTO: Codable, Sendable {
    public let conversations: [ConversationDTO]
    public let messages: [MessageSearchHitDTO]
    public let users: [UserDTO]

    public init(conversations: [ConversationDTO], messages: [MessageSearchHitDTO], users: [UserDTO]) {
        self.conversations = conversations
        self.messages = messages
        self.users = users
    }
}
