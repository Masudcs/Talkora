@testable import Talkora
import Foundation
import XCTest
@testable import Core
@testable import Stories

@MainActor
final class StatusViewModelTests: XCTestCase {
    private func makeUser(_ id: String, _ name: String) -> User {
        User(id: id, displayName: name, handle: "@\(id)", avatarURL: nil, status: .online, createdAt: Date())
    }

    private func makeStory(_ id: String, author: String, viewers: [String] = []) -> Story {
        Story(id: id, authorId: author, createdAt: Date(), expiresAt: Date().addingTimeInterval(3600),
              backgroundColorHex: nil, mediaURL: nil, overlayText: "hi", overlayEmoji: nil,
              privacy: .everyone, notifyOnScreenshot: false, viewerIds: viewers, isHighlighted: false)
    }

    private func makeViewModel(stories: StubStoryRepository, users: StubUserRepository) -> StatusViewModel {
        StatusViewModel(storyRepository: stories, userRepository: users)
    }

    func test_load_splitsMyStoriesFromOthers() async {
        let stories = StubStoryRepository()
        stories.activeStoriesResult = .success([makeStory("s1", author: "me"), makeStory("s2", author: "bob", viewers: ["me"])])
        let users = StubUserRepository()
        users.currentUserResult = .success(makeUser("me", "Me"))
        users.userResult = .success(makeUser("bob", "Bob"))
        let viewModel = makeViewModel(stories: stories, users: users)

        await viewModel.load()

        XCTAssertEqual(viewModel.myActiveStories.map(\.id), ["s1"])
        XCTAssertEqual(viewModel.othersStoriesGrouped.map(\.author), ["bob"])
        XCTAssertTrue(viewModel.hasViewedAll(viewModel.othersStoriesGrouped[0].stories))
    }

    func test_load_withNoStories_staysLoadedSoMyStatusRowStillRenders() async {
        let users = StubUserRepository()
        users.currentUserResult = .success(makeUser("me", "Me"))
        let viewModel = makeViewModel(stories: StubStoryRepository(), users: users)

        await viewModel.load()

        XCTAssertEqual(viewModel.state.value?.count, 0)
    }

    func test_load_failure_setsFailed() async {
        let viewModel = makeViewModel(stories: StubStoryRepository(), users: StubUserRepository())

        await viewModel.load()

        XCTAssertNotNil(viewModel.state.error)
    }

    func test_deleteMyStory_removesItFromState() async {
        let stories = StubStoryRepository()
        let mine = makeStory("s1", author: "me")
        stories.activeStoriesResult = .success([mine, makeStory("s2", author: "me")])
        let users = StubUserRepository()
        users.currentUserResult = .success(makeUser("me", "Me"))
        let viewModel = makeViewModel(stories: stories, users: users)
        await viewModel.load()

        await viewModel.deleteMyStory(mine)

        XCTAssertEqual(stories.deletedStoryIds, ["s1"])
        XCTAssertEqual(viewModel.myActiveStories.map(\.id), ["s2"])
    }
}
