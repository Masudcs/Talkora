import Foundation

/// One-to-many broadcast, distinct from a `Conversation` group: followers (not
/// bidirectional members) receive posts, and only admins can post — closer to a
/// Telegram channel than a WhatsApp/Discord group.
public struct Channel: Identifiable, Hashable, Sendable {
    public let id: String
    public let title: String
    public let description: String?
    public let ownerId: String
    public let adminIds: [String]
    public let followerCount: Int
    public let isFollowing: Bool
    public let createdAt: Date

    public func isAdmin(_ userId: String) -> Bool {
        userId == ownerId || adminIds.contains(userId)
    }

    public init(id: String, title: String, description: String?, ownerId: String, adminIds: [String], followerCount: Int, isFollowing: Bool, createdAt: Date) {
        self.id = id
        self.title = title
        self.description = description
        self.ownerId = ownerId
        self.adminIds = adminIds
        self.followerCount = followerCount
        self.isFollowing = isFollowing
        self.createdAt = createdAt
    }
}
