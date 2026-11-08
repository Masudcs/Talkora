import Foundation

public protocol IStoryRepository: Sendable {
    /// Every non-expired story visible to the current user (own + others per privacy),
    /// filtered server-side — plus any of the current user's permanent Highlights.
    func activeStories() async throws -> [Story]
    func highlights(authorId: String) async throws -> [Story]
    func createStory(
        backgroundColorHex: String?,
        mediaAssetId: String?,
        overlayText: String?,
        overlayEmoji: String?,
        privacy: StoryPrivacy,
        notifyOnScreenshot: Bool
    ) async throws -> Story
    func markViewed(_ storyId: String) async throws
    func viewers(of storyId: String) async throws -> [User]
    func setHighlighted(_ storyId: String, isHighlighted: Bool) async throws -> Story
    func deleteStory(_ storyId: String) async throws
    /// Uncommon (Instagram): a curated subset of contacts for `.closeFriends`-privacy stories.
    func closeFriendIds() async throws -> [String]
    func setCloseFriends(_ userIds: [String]) async throws
}
