@testable import Talkora
import Foundation
@testable import Core

final class StubStoryRepository: IStoryRepository {
    var activeStoriesResult: Result<[Story], Error> = .success([])
    var highlightsResult: Result<[Story], Error> = .success([])
    var createStoryResult: Result<Story, Error> = .failure(StubFailure.notConfigured)
    var markViewedResult: Result<Void, Error> = .success(())
    var viewersResult: Result<[User], Error> = .success([])
    var setHighlightedResult: Result<Story, Error> = .failure(StubFailure.notConfigured)
    var deleteStoryResult: Result<Void, Error> = .success(())
    var closeFriendIdsResult: Result<[String], Error> = .success([])
    var setCloseFriendsResult: Result<Void, Error> = .success(())
    private(set) var deletedStoryIds: [String] = []

    func activeStories() async throws -> [Story] {
        try activeStoriesResult.get()
    }

    func highlights(authorId: String) async throws -> [Story] {
        try highlightsResult.get()
    }

    func createStory(
        backgroundColorHex: String?,
        mediaAssetId: String?,
        overlayText: String?,
        overlayEmoji: String?,
        privacy: StoryPrivacy,
        notifyOnScreenshot: Bool
    ) async throws -> Story {
        try createStoryResult.get()
    }

    func markViewed(_ storyId: String) async throws {
        try markViewedResult.get()
    }

    func viewers(of storyId: String) async throws -> [User] {
        try viewersResult.get()
    }

    func setHighlighted(_ storyId: String, isHighlighted: Bool) async throws -> Story {
        try setHighlightedResult.get()
    }

    func deleteStory(_ storyId: String) async throws {
        deletedStoryIds.append(storyId)
        try deleteStoryResult.get()
    }

    func closeFriendIds() async throws -> [String] {
        try closeFriendIdsResult.get()
    }

    func setCloseFriends(_ userIds: [String]) async throws {
        try setCloseFriendsResult.get()
    }
}
