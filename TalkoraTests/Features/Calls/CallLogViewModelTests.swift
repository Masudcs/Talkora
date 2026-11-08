@testable import Talkora
import Foundation
import XCTest
@testable import Core
@testable import Calls

private func makeUser(_ id: String, _ name: String = "User") -> User {
    User(id: id, displayName: name, handle: "@\(id)", avatarURL: nil, status: .online, createdAt: Date())
}

private func makeConversation(_ id: String, kind: ConversationKind = .direct, participants: [String] = ["me", "bob"]) -> Conversation {
    Conversation(id: id, kind: kind, title: id, participantIds: participants, lastMessagePreview: nil, updatedAt: Date())
}

private func makeCall(_ id: String, counterpart: String = "bob") -> Call {
    Call(id: id, conversationId: "c1", counterpartId: counterpart, type: .voice, direction: .outgoing,
         outcome: .completed, startedAt: Date(), duration: 10)
}

@MainActor
final class CallLogViewModelTests: XCTestCase {
    private func makeViewModel(calls: StubCallRepository, chat: StubChatRepository = StubChatRepository(), users: StubUserRepository) -> CallLogViewModel {
        CallLogViewModel(callRepository: calls, chatRepository: chat, userRepository: users)
    }

    private func makeUsers() -> StubUserRepository {
        let users = StubUserRepository()
        users.currentUserResult = .success(makeUser("me"))
        users.userResult = .success(makeUser("bob", "Bob"))
        return users
    }

    func test_load_success_setsLoadedAndNames() async {
        let calls = StubCallRepository()
        let call = makeCall("k1")
        calls.callHistoryResult = .success([call])
        let viewModel = makeViewModel(calls: calls, users: makeUsers())

        await viewModel.load()

        XCTAssertEqual(viewModel.state.value?.map(\.id), ["k1"])
        XCTAssertEqual(viewModel.name(for: call), "Bob")
    }

    func test_load_withNoCalls_setsEmpty() async {
        let viewModel = makeViewModel(calls: StubCallRepository(), users: makeUsers())

        await viewModel.load()

        guard case .empty = viewModel.state else { return XCTFail("expected .empty, got \(viewModel.state)") }
    }

    func test_load_failure_setsFailed() async {
        let viewModel = makeViewModel(calls: StubCallRepository(), users: StubUserRepository())

        await viewModel.load()

        XCTAssertNotNil(viewModel.state.error)
    }

    func test_name_forUnknownCounterpart_isUnknown() {
        let viewModel = makeViewModel(calls: StubCallRepository(), users: StubUserRepository())

        XCTAssertEqual(viewModel.name(for: makeCall("k1")), "Unknown")
    }

    func test_redialRequest_buildsOutgoingRequestFromCall() async {
        let calls = StubCallRepository()
        let call = Call(id: "k1", conversationId: "c1", counterpartId: "bob", type: .video, direction: .incoming,
                        outcome: .missed, startedAt: Date(), duration: 0)
        calls.callHistoryResult = .success([call])
        let viewModel = makeViewModel(calls: calls, users: makeUsers())
        await viewModel.load()

        let request = viewModel.redialRequest(for: call)

        XCTAssertEqual(request.conversationId, "c1")
        XCTAssertEqual(request.counterpartId, "bob")
        XCTAssertEqual(request.counterpartName, "Bob")
        XCTAssertEqual(request.type, .video)
        XCTAssertEqual(request.direction, .outgoing)
    }

    func test_randomIncomingCallRequest_usesDirectConversationCounterpart() async {
        let chat = StubChatRepository()
        chat.conversationsResult = .success([
            makeConversation("g1", kind: .group, participants: ["me", "x", "y"]),
            makeConversation("c1")
        ])
        let viewModel = makeViewModel(calls: StubCallRepository(), chat: chat, users: makeUsers())
        await viewModel.load()

        let request = viewModel.randomIncomingCallRequest()

        XCTAssertEqual(request?.conversationId, "c1")
        XCTAssertEqual(request?.counterpartId, "bob")
        XCTAssertEqual(request?.direction, .incoming)
    }

    func test_randomIncomingCallRequest_withoutDirectConversations_returnsNil() async {
        let viewModel = makeViewModel(calls: StubCallRepository(), users: makeUsers())
        await viewModel.load()

        XCTAssertNil(viewModel.randomIncomingCallRequest())
    }
}
