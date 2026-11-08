import Foundation

/// The full channels surface, split by concern: the channel directory, posts, and communities.
public protocol IChannelRepository: IChannelCatalogRepository, IChannelPostRepository, ICommunityRepository {}

public protocol IChannelCatalogRepository: Sendable {
    /// The public directory — every channel, followed or not (Improve: discoverable,
    /// not just found via an invite link).
    func allChannels() async throws -> [Channel]
    func myChannels() async throws -> [Channel]
    func channel(id: String) async throws -> Channel
    func createChannel(title: String, description: String?) async throws -> Channel
    func follow(_ channelId: String) async throws -> Channel
    func unfollow(_ channelId: String) async throws -> Channel
}

public protocol IChannelPostRepository: Sendable {
    func posts(channelId: String) async throws -> [ChannelPost]
    /// Server-enforced admin-only posting — not just hidden client-side.
    func createPost(channelId: String, text: String) async throws -> ChannelPost
    func registerView(postId: String, channelId: String) async throws -> ChannelPost
}

public protocol ICommunityRepository: Sendable {
    func communities() async throws -> [Community]
    func community(id: String) async throws -> Community
    func createCommunity(title: String, description: String?) async throws -> Community
    func linkGroup(_ conversationId: String, toCommunity communityId: String) async throws -> Community
    func linkChannel(_ channelId: String, toCommunity communityId: String) async throws -> Community
}
