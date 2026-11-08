import Foundation

/// Improve: filters are structured (sender/media/date), not just an unstructured text
/// match — the search bar still accepts `from:`/`has:media`/`after:`/`before:` typed
/// query syntax, parsed into this by `SearchQueryParser`.
public struct MessageSearchFilter: Sendable, Equatable {
    public var senderId: String?
    public var hasMediaOnly: Bool = false
    public var after: Date?
    public var before: Date?

    public var isEmpty: Bool {
        senderId == nil && !hasMediaOnly && after == nil && before == nil
    }

    public init(senderId: String? = nil, hasMediaOnly: Bool = false, after: Date? = nil, before: Date? = nil) {
        self.senderId = senderId
        self.hasMediaOnly = hasMediaOnly
        self.after = after
        self.before = before
    }
}

/// A message hit from a global (cross-chat) search — carries enough about its parent
/// conversation to jump straight to it, since the message alone doesn't say where it lives.
public struct MessageSearchHit: Identifiable, Sendable {
    public var id: String { message.id }
    public let message: Message
    public let conversationId: String
    public let conversationTitle: String

    public init(message: Message, conversationId: String, conversationTitle: String) {
        self.message = message
        self.conversationId = conversationId
        self.conversationTitle = conversationTitle
    }
}

/// Cross-chat search results, grouped by conversations, messages and people.
public struct GlobalSearchResults: Sendable {
    public let conversations: [Conversation]
    public let messages: [MessageSearchHit]
    public let users: [User]

    public static let empty = GlobalSearchResults(conversations: [], messages: [], users: [])

    public var isEmpty: Bool {
        conversations.isEmpty && messages.isEmpty && users.isEmpty
    }

    public init(conversations: [Conversation], messages: [MessageSearchHit], users: [User]) {
        self.conversations = conversations
        self.messages = messages
        self.users = users
    }
}
