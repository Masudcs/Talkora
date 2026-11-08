@testable import Talkora
import Foundation
import XCTest
@testable import Core
@testable import Messaging

@MainActor
final class CreateGroupViewModelTests: XCTestCase {
    private func makeUser(_ id: String, _ name: String) -> User {
        User(id: id, displayName: name, handle: "@\(id)", avatarURL: nil, status: .online, createdAt: Date())
    }

    func test_loadCandidates_excludesCurrentUser() async {
        let userStub = StubUserRepository()
        userStub.currentUserResult = .success(makeUser("u1", "You"))
        userStub.allUsersResult = .success([makeUser("u1", "You"), makeUser("u2", "Amara")])
        let viewModel = CreateGroupViewModel(chatRepository: StubChatRepository(), userRepository: userStub)

        await viewModel.loadCandidates()

        XCTAssertEqual(viewModel.candidates.map(\.id), ["u2"])
    }

    func test_canCreate_requiresTitleAndAtLeastOneMember() {
        let viewModel = CreateGroupViewModel(chatRepository: StubChatRepository(), userRepository: StubUserRepository())
        XCTAssertFalse(viewModel.canCreate)

        viewModel.title = "Book Club"
        XCTAssertFalse(viewModel.canCreate)

        viewModel.toggle("u2")
        XCTAssertTrue(viewModel.canCreate)
    }

    func test_create_success_updatesState() async {
        let chatStub = StubChatRepository()
        let group = Conversation(id: "g1", kind: .group, title: "Book Club", participantIds: ["u1", "u2"], lastMessagePreview: nil, updatedAt: Date())
        chatStub.createGroupResult = .success(group)
        let viewModel = CreateGroupViewModel(chatRepository: chatStub, userRepository: StubUserRepository())
        viewModel.title = "Book Club"
        viewModel.toggle("u2")

        await viewModel.create()

        XCTAssertEqual(viewModel.state.value?.id, "g1")
    }
}
