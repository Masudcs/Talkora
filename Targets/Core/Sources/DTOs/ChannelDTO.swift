import Foundation

/// Wire-format channel. Followers are sent as an id list; the mapper reduces it to a count plus an `isFollowing` flag for the current user.
public struct ChannelDTO: Codable, Sendable, Hashable {
    public let id: String
    public let title: String
    public let description: String?
    public let ownerId: String
    public let adminIds: [String]
    public let followerIds: [String]
    public let createdAt: String

    public init(id: String, title: String, description: String?, ownerId: String, adminIds: [String] = [], followerIds: [String] = [], createdAt: String) {
        self.id = id
        self.title = title
        self.description = description
        self.ownerId = ownerId
        self.adminIds = adminIds
        self.followerIds = followerIds
        self.createdAt = createdAt
    }

    public func with(followerIds: [String]? = nil) -> ChannelDTO {
        ChannelDTO(
            id: id,
            title: title,
            description: description,
            ownerId: ownerId,
            adminIds: adminIds,
            followerIds: followerIds ?? self.followerIds,
            createdAt: createdAt
        )
    }
}
