@testable import Talkora
import Foundation
import XCTest
@testable import Core
@testable import Stories

private func makeUser(_ id: String, _ name: String = "User") -> User {
    User(id: id, displayName: name, handle: "@\(id)", avatarURL: nil, status: .online, createdAt: Date())
}

private func makeStory(_ id: String, author: String) -> Story {
    Story(id: id, authorId: author, createdAt: Date(), expiresAt: Date().addingTimeInterval(3600),
          backgroundColorHex: nil, mediaURL: nil, overlayText: "hi", overlayEmoji: nil,
          privacy: .everyone, notifyOnScreenshot: false, viewerIds: [], isHighlighted: false)
}

@MainActor
final class StoryViewerViewModelTests: XCTestCase {
    private func makeViewModel(stories: [Story], repo: StubStoryRepository = StubStoryRepository()) -> StoryViewerViewModel {
        StoryViewerViewModel(stories: stories, currentUserId: "me", storyRepository: repo)
    }

    func test_currentStory_returnsFirstStory() {
        let viewModel = makeViewModel(stories: [makeStory("s1", author: "bob"), makeStory("s2", author: "bob")])

        XCTAssertEqual(viewModel.currentStory?.id, "s1")
        XCTAssertFalse(viewModel.isOwnStory)
    }

    func test_currentStory_withNoStories_isNil() {
        let viewModel = makeViewModel(stories: [])

        XCTAssertNil(viewModel.currentStory)
        XCTAssertFalse(viewModel.isOwnStory)
    }

    func test_isOwnStory_whenAuthorIsCurrentUser_isTrue() {
        let viewModel = makeViewModel(stories: [makeStory("s1", author: "me")])

        XCTAssertTrue(viewModel.isOwnStory)
    }

    func test_next_onLastStory_marksFinished() {
        let viewModel = makeViewModel(stories: [makeStory("s1", author: "bob")])

        viewModel.next()

        XCTAssertTrue(viewModel.isFinished)
        XCTAssertEqual(viewModel.currentIndex, 0)
    }

    func test_next_withMoreStories_advancesIndexAndResetsProgress() {
        let viewModel = makeViewModel(stories: [makeStory("s1", author: "bob"), makeStory("s2", author: "bob")])

        viewModel.next()
        viewModel.stop()

        XCTAssertEqual(viewModel.currentIndex, 1)
        XCTAssertEqual(viewModel.progress, 0)
        XCTAssertFalse(viewModel.isFinished)
    }

    func test_previous_onFirstStory_staysAtZero() {
        let viewModel = makeViewModel(stories: [makeStory("s1", author: "bob"), makeStory("s2", author: "bob")])

        viewModel.previous()
        viewModel.stop()

        XCTAssertEqual(viewModel.currentIndex, 0)
    }

    func test_previous_afterNext_goesBack() {
        let viewModel = makeViewModel(stories: [makeStory("s1", author: "bob"), makeStory("s2", author: "bob")])

        viewModel.next()
        viewModel.previous()
        viewModel.stop()

        XCTAssertEqual(viewModel.currentIndex, 0)
    }

    func test_loadViewers_success_populatesViewers() async {
        let repo = StubStoryRepository()
        repo.viewersResult = .success([makeUser("bob"), makeUser("amy")])
        let viewModel = makeViewModel(stories: [makeStory("s1", author: "me")], repo: repo)

        await viewModel.loadViewers()

        XCTAssertEqual(viewModel.viewers.map(\.id), ["bob", "amy"])
    }

    func test_loadViewers_failure_leavesViewersEmpty() async {
        let repo = StubStoryRepository()
        repo.viewersResult = .failure(StubFailure.notConfigured)
        let viewModel = makeViewModel(stories: [makeStory("s1", author: "me")], repo: repo)

        await viewModel.loadViewers()

        XCTAssertTrue(viewModel.viewers.isEmpty)
    }
}
