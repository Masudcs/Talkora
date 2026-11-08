@testable import Talkora
import Foundation
import XCTest
@testable import Core
@testable import Stories

private func makeUser(_ id: String, _ name: String = "User") -> User {
    User(id: id, displayName: name, handle: "@\(id)", avatarURL: nil, status: .online, createdAt: Date())
}

@MainActor
final class CloseFriendsViewModelTests: XCTestCase {
    private func makeViewModel(stories: StubStoryRepository, users: StubUserRepository) -> CloseFriendsViewModel {
        CloseFriendsViewModel(storyRepository: stories, userRepository: users)
    }

    func test_load_success_excludesMeAndPreselectsCloseFriends() async {
        let stories = StubStoryRepository()
        stories.closeFriendIdsResult = .success(["bob"])
        let users = StubUserRepository()
        users.currentUserResult = .success(makeUser("me"))
        users.allUsersResult = .success([makeUser("me"), makeUser("bob"), makeUser("amy")])
        let viewModel = makeViewModel(stories: stories, users: users)

        await viewModel.load()

        XCTAssertEqual(viewModel.candidates.map(\.id), ["bob", "amy"])
        XCTAssertEqual(viewModel.selectedIds, ["bob"])
    }

    func test_load_failure_clearsCandidates() async {
        let viewModel = makeViewModel(stories: StubStoryRepository(), users: StubUserRepository())

        await viewModel.load()

        XCTAssertTrue(viewModel.candidates.isEmpty)
        XCTAssertTrue(viewModel.selectedIds.isEmpty)
    }

    func test_toggle_addsThenRemovesId() {
        let viewModel = makeViewModel(stories: StubStoryRepository(), users: StubUserRepository())

        viewModel.toggle("bob")
        XCTAssertTrue(viewModel.selectedIds.contains("bob"))

        viewModel.toggle("bob")
        XCTAssertFalse(viewModel.selectedIds.contains("bob"))
    }

    func test_save_failure_doesNotThrowOrChangeSelection() async {
        let stories = StubStoryRepository()
        stories.setCloseFriendsResult = .failure(StubFailure.notConfigured)
        let viewModel = makeViewModel(stories: stories, users: StubUserRepository())
        viewModel.toggle("bob")

        await viewModel.save()

        XCTAssertEqual(viewModel.selectedIds, ["bob"])
    }
}
