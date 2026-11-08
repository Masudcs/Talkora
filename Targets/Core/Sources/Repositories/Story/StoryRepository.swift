import Foundation

/// Stories, highlights and close friends, over `APIClientProtocol` — behaves the same against the mock, stubbed and live backends.
public final class StoryRepository: IStoryRepository {
    private let api: APIClientProtocol

    public init(api: APIClientProtocol = APIClientProvider.shared.client) {
        self.api = api
    }

    public func activeStories() async throws -> [Story] {
        let dtos: [StoryDTO] = try await api.request(StoryRoutes.active)
        return dtos.map { $0.toDomain() }
    }

    public func highlights(authorId: String) async throws -> [Story] {
        let dtos: [StoryDTO] = try await api.request(StoryRoutes.highlights(authorId: authorId))
        return dtos.map { $0.toDomain() }
    }

    public func createStory(
        backgroundColorHex: String?,
        mediaAssetId: String?,
        overlayText: String?,
        overlayEmoji: String?,
        privacy: StoryPrivacy,
        notifyOnScreenshot: Bool
    ) async throws -> Story {
        let dto: StoryDTO = try await api.request(
            StoryRoutes.create(
                backgroundColorHex: backgroundColorHex,
                mediaAssetId: mediaAssetId,
                overlayText: overlayText,
                overlayEmoji: overlayEmoji,
                privacy: privacy.rawValue,
                notifyOnScreenshot: notifyOnScreenshot
            )
        )
        return dto.toDomain()
    }

    public func markViewed(_ storyId: String) async throws {
        try await api.requestVoid(StoryRoutes.markViewed(storyId: storyId))
    }

    public func viewers(of storyId: String) async throws -> [User] {
        let dtos: [UserDTO] = try await api.request(StoryRoutes.viewers(storyId: storyId))
        return dtos.map { $0.toDomain() }
    }

    public func setHighlighted(_ storyId: String, isHighlighted: Bool) async throws -> Story {
        let dto: StoryDTO = try await api.request(
            StoryRoutes.setHighlighted(storyId: storyId, isHighlighted: isHighlighted)
        )
        return dto.toDomain()
    }

    public func deleteStory(_ storyId: String) async throws {
        try await api.requestVoid(StoryRoutes.delete(storyId: storyId))
    }

    public func closeFriendIds() async throws -> [String] {
        try await api.request(StoryRoutes.closeFriends)
    }

    public func setCloseFriends(_ userIds: [String]) async throws {
        try await api.requestVoid(StoryRoutes.setCloseFriends(userIds: userIds))
    }
}
