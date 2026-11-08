import Foundation

/// A group conversation or channel attached to a community; `itemId` is that conversation's or channel's own id.
public struct CommunityLinkedItemDTO: Codable, Sendable, Hashable {
    public let itemId: String
    public let kind: String // "group" | "channel"
    public let title: String

    public init(itemId: String, kind: String, title: String) {
        self.itemId = itemId
        self.kind = kind
        self.title = title
    }
}

/// Wire-format community: a named collection of linked groups and channels.
public struct CommunityDTO: Codable, Sendable, Hashable {
    public let id: String
    public let title: String
    public let description: String?
    public let ownerId: String
    public let memberIds: [String]
    public let linkedItems: [CommunityLinkedItemDTO]
    public let createdAt: String

    public init(id: String, title: String, description: String?, ownerId: String, memberIds: [String] = [], linkedItems: [CommunityLinkedItemDTO] = [], createdAt: String) {
        self.id = id
        self.title = title
        self.description = description
        self.ownerId = ownerId
        self.memberIds = memberIds
        self.linkedItems = linkedItems
        self.createdAt = createdAt
    }

    public func with(linkedItems: [CommunityLinkedItemDTO]? = nil) -> CommunityDTO {
        CommunityDTO(
            id: id,
            title: title,
            description: description,
            ownerId: ownerId,
            memberIds: memberIds,
            linkedItems: linkedItems ?? self.linkedItems,
            createdAt: createdAt
        )
    }
}
