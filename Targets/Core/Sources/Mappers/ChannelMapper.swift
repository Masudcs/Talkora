import Foundation

/// Needs the current user's id to derive `isFollowing`; the follower list itself is not exposed.
public extension ChannelDTO {
    func toDomain(currentUserId: String) -> Channel {
        Channel(
            id: id,
            title: title,
            description: description,
            ownerId: ownerId,
            adminIds: adminIds,
            followerCount: followerIds.count,
            isFollowing: followerIds.contains(currentUserId),
            createdAt: ISO8601.date(from: createdAt)
        )
    }
}

public extension ChannelPostDTO {
    func toDomain() -> ChannelPost {
        ChannelPost(
            id: id,
            channelId: channelId,
            authorId: authorId,
            text: text,
            createdAt: ISO8601.date(from: createdAt),
            viewCount: viewerIds.count
        )
    }
}
