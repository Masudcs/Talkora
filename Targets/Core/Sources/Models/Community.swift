import Foundation

public enum CommunityLinkedItemKind: String, Sendable {
    case group
    case channel
}

public struct CommunityLinkedItem: Identifiable, Hashable, Sendable {
    /// The linked conversation's or channel's own id — not a separate identity.
    public var id: String { itemId }
    public let itemId: String
    public let kind: CommunityLinkedItemKind
    public let title: String

    public init(itemId: String, kind: CommunityLinkedItemKind, title: String) {
        self.itemId = itemId
        self.kind = kind
        self.title = title
    }
}

/// Improve: a community explicitly groups multiple existing chats/channels under one
/// roof, distinct from both a group (single conversation) and a channel (single broadcast).
public struct Community: Identifiable, Hashable, Sendable {
    public let id: String
    public let title: String
    public let description: String?
    public let ownerId: String
    public let memberIds: [String]
    public let linkedItems: [CommunityLinkedItem]
    public let createdAt: Date

    public init(id: String, title: String, description: String?, ownerId: String, memberIds: [String], linkedItems: [CommunityLinkedItem], createdAt: Date) {
        self.id = id
        self.title = title
        self.description = description
        self.ownerId = ownerId
        self.memberIds = memberIds
        self.linkedItems = linkedItems
        self.createdAt = createdAt
    }
}
