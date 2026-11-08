@testable import Talkora
import Foundation
import XCTest
@testable import Core
@testable import Messaging

@MainActor
final class ConversationViewModelTests: XCTestCase {
    private func makeUser(_ id: String, _ name: String = "User", bio: String = "", avatarURL: URL? = nil) -> User {
        User(id: id, displayName: name, handle: "@\(id)", avatarURL: avatarURL, status: .online, createdAt: Date(), bio: bio)
    }

    private func makeConversation(_ id: String, participants: [String] = ["u1"]) -> Conversation {
        Conversation(id: id, kind: .group, title: "Group \(id)", participantIds: participants, lastMessagePreview: nil, updatedAt: Date())
    }

    // MARK: - ConversationListViewModel

    func test_conversationListLoad_success_setsLoaded() async {
        let stub = StubChatRepository()
        stub.conversationsResult = .success([makeConversation("g1"), makeConversation("g2")])
        let viewModel = ConversationListViewModel(repository: stub)

        await viewModel.load()

        XCTAssertEqual(viewModel.state.value?.count, 2)
    }

    func test_conversationListLoad_noItems_setsEmpty() async {
        let viewModel = ConversationListViewModel(repository: StubChatRepository())

        await viewModel.load()

        guard case .empty = viewModel.state else {
            return XCTFail("Expected empty state")
        }
    }

    func test_conversationListLoad_failure_setsFailed() async {
        let stub = StubChatRepository()
        stub.conversationsResult = .failure(StubFailure.notConfigured)
        let viewModel = ConversationListViewModel(repository: stub)

        await viewModel.load()

        XCTAssertNotNil(viewModel.state.error)
    }

    // MARK: - AddMembersViewModel

    private func makeAddMembers(chat: StubChatRepository, users: StubUserRepository) -> AddMembersViewModel {
        AddMembersViewModel(conversationId: "g1", chatRepository: chat, userRepository: users)
    }

    func test_addMembersLoadCandidates_excludesExistingParticipants() async {
        let chat = StubChatRepository()
        chat.conversationResult = .success(makeConversation("g1", participants: ["u1", "u2"]))
        let users = StubUserRepository()
        users.allUsersResult = .success([makeUser("u1"), makeUser("u2"), makeUser("u3")])
        let viewModel = makeAddMembers(chat: chat, users: users)

        await viewModel.loadCandidates()

        XCTAssertEqual(viewModel.candidates.map(\.id), ["u3"])
    }

    func test_addMembersLoadCandidates_failure_leavesCandidatesEmpty() async {
        let chat = StubChatRepository()
        chat.conversationResult = .failure(StubFailure.notConfigured)
        let viewModel = makeAddMembers(chat: chat, users: StubUserRepository())

        await viewModel.loadCandidates()

        XCTAssertTrue(viewModel.candidates.isEmpty)
    }

    func test_addMembersToggle_addsAndRemovesSelection() {
        let viewModel = makeAddMembers(chat: StubChatRepository(), users: StubUserRepository())

        viewModel.toggle("u3")
        XCTAssertEqual(viewModel.selectedUserIds, ["u3"])
        XCTAssertTrue(viewModel.canAdd)

        viewModel.toggle("u3")
        XCTAssertTrue(viewModel.selectedUserIds.isEmpty)
        XCTAssertFalse(viewModel.canAdd)
    }

    func test_addMembersAddSelected_withoutSelection_doesNothing() async {
        let viewModel = makeAddMembers(chat: StubChatRepository(), users: StubUserRepository())

        await viewModel.addSelectedMembers()

        guard case .idle = viewModel.state else {
            return XCTFail("Expected idle state")
        }
    }

    func test_addMembersAddSelected_success_setsLoadedConversation() async {
        let chat = StubChatRepository()
        let updated = makeConversation("g1", participants: ["u1", "u3"])
        chat.addMemberResult = .success(updated)
        chat.conversationResult = .success(updated)
        let viewModel = makeAddMembers(chat: chat, users: StubUserRepository())
        viewModel.toggle("u3")

        await viewModel.addSelectedMembers()

        XCTAssertEqual(viewModel.state.value?.participantIds, ["u1", "u3"])
    }

    func test_addMembersAddSelected_failure_setsFailed() async {
        let chat = StubChatRepository()
        chat.addMemberResult = .failure(StubFailure.notConfigured)
        let viewModel = makeAddMembers(chat: chat, users: StubUserRepository())
        viewModel.toggle("u3")

        await viewModel.addSelectedMembers()

        XCTAssertNotNil(viewModel.state.error)
    }
}
