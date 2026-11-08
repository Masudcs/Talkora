import Foundation

/// Channels, posts and communities, over `APIClientProtocol` — behaves the same against the mock, stubbed and live backends.
public final class ChannelRepository: IChannelRepository {
    private let api: APIClientProtocol
    private let userRepository: IUserRepository

    public init(api: APIClientProtocol = APIClientProvider.shared.client, userRepository: IUserRepository = UserRepository()) {
        self.api = api
        self.userRepository = userRepository
    }

    public func allChannels() async throws -> [Channel] {
        let currentUserId = try await userRepository.currentUser().id
        let dtos: [ChannelDTO] = try await api.request(ChannelRoutes.allChannels)
        return dtos.map { $0.toDomain(currentUserId: currentUserId) }
    }

    public func myChannels() async throws -> [Channel] {
        let currentUserId = try await userRepository.currentUser().id
        let dtos: [ChannelDTO] = try await api.request(ChannelRoutes.myChannels)
        return dtos.map { $0.toDomain(currentUserId: currentUserId) }
    }

    public func channel(id: String) async throws -> Channel {
        let currentUserId = try await userRepository.currentUser().id
        let dto: ChannelDTO = try await api.request(ChannelRoutes.channel(id: id))
        return dto.toDomain(currentUserId: currentUserId)
    }

    public func createChannel(title: String, description: String?) async throws -> Channel {
        let currentUserId = try await userRepository.currentUser().id
        let dto: ChannelDTO = try await api.request(ChannelRoutes.createChannel(title: title, description: description))
        return dto.toDomain(currentUserId: currentUserId)
    }

    public func follow(_ channelId: String) async throws -> Channel {
        let currentUserId = try await userRepository.currentUser().id
        let dto: ChannelDTO = try await api.request(ChannelRoutes.follow(channelId: channelId))
        return dto.toDomain(currentUserId: currentUserId)
    }

    public func unfollow(_ channelId: String) async throws -> Channel {
        let currentUserId = try await userRepository.currentUser().id
        let dto: ChannelDTO = try await api.request(ChannelRoutes.unfollow(channelId: channelId))
        return dto.toDomain(currentUserId: currentUserId)
    }

    public func posts(channelId: String) async throws -> [ChannelPost] {
        let dtos: [ChannelPostDTO] = try await api.request(ChannelRoutes.posts(channelId: channelId))
        return dtos.map { $0.toDomain() }
    }

    public func createPost(channelId: String, text: String) async throws -> ChannelPost {
        let dto: ChannelPostDTO = try await api.request(
            ChannelRoutes.createPost(channelId: channelId, text: text)
        )
        return dto.toDomain()
    }

    public func registerView(postId: String, channelId: String) async throws -> ChannelPost {
        let dto: ChannelPostDTO = try await api.request(
            ChannelRoutes.registerView(channelId: channelId, postId: postId)
        )
        return dto.toDomain()
    }

    public func communities() async throws -> [Community] {
        let dtos: [CommunityDTO] = try await api.request(ChannelRoutes.communities)
        return dtos.map { $0.toDomain() }
    }

    public func community(id: String) async throws -> Community {
        let dto: CommunityDTO = try await api.request(ChannelRoutes.community(id: id))
        return dto.toDomain()
    }

    public func createCommunity(title: String, description: String?) async throws -> Community {
        let dto: CommunityDTO = try await api.request(ChannelRoutes.createCommunity(title: title, description: description))
        return dto.toDomain()
    }

    public func linkGroup(_ conversationId: String, toCommunity communityId: String) async throws -> Community {
        let dto: CommunityDTO = try await api.request(
            ChannelRoutes.linkGroup(communityId: communityId, conversationId: conversationId)
        )
        return dto.toDomain()
    }

    public func linkChannel(_ channelId: String, toCommunity communityId: String) async throws -> Community {
        let dto: CommunityDTO = try await api.request(
            ChannelRoutes.linkChannel(communityId: communityId, channelId: channelId)
        )
        return dto.toDomain()
    }
}
