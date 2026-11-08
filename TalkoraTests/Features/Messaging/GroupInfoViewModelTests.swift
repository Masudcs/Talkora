@testable import Talkora
import Foundation
import XCTest
@testable import Core
@testable import Messaging

@MainActor
final class GroupInfoViewModelTests: XCTestCase {
    private func makeUser(_ id: String, _ name: String) -> User {
        User(id: id, displayName: name, handle: "@\(id)", avatarURL: nil, status: .online, createdAt: Date())
    }

    func test_load_populatesMembersAndAdminFlag() async {
        let chatStub = StubChatRepository()
        let group = Conversation(
            id: "g1", kind: .group, title: "Design Team", participantIds: ["u1", "u7"],
            lastMessagePreview: nil, updatedAt: Date(),
            members: [GroupMember(userId: "u1", role: .owner), GroupMember(userId: "u7", role: .member)]
        )
        chatStub.conversationResult = .success(group)
        let userStub = StubUserRepository()
        userStub.currentUserResult = .success(makeUser("u1", "You"))
        userStub.userResult = .success(makeUser("u7", "Sofia"))
        let viewModel = GroupInfoViewModel(conversationId: "g1", chatRepository: chatStub, userRepository: userStub)

        await viewModel.load()

        XCTAssertTrue(viewModel.isCurrentUserAdmin)
        XCTAssertEqual(viewModel.members.count, 2)
        XCTAssertEqual(viewModel.members.first?.role, .owner)
    }

    func test_leaveGroup_setsDidLeave() async {
        let chatStub = StubChatRepository()
        let group = Conversation(id: "g1", kind: .group, title: "Design Team", participantIds: ["u1"], lastMessagePreview: nil, updatedAt: Date())
        chatStub.conversationResult = .success(group)
        chatStub.removeMemberResult = .success(group)
        let userStub = StubUserRepository()
        userStub.currentUserResult = .success(makeUser("u1", "You"))
        let viewModel = GroupInfoViewModel(conversationId: "g1", chatRepository: chatStub, userRepository: userStub)
        await viewModel.load()

        await viewModel.leaveGroup()

        XCTAssertTrue(viewModel.didLeave)
    }
}
