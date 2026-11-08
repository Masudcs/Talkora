@testable import Talkora
import Foundation
import XCTest
@testable import Core
@testable import ContactsFeature

private func makeUser(_ id: String, _ name: String = "User") -> User {
    User(id: id, displayName: name, handle: "@\(id)", avatarURL: nil, status: .online, createdAt: Date())
}

private func makeRequest(_ id: String, from: String) -> ContactRequest {
    ContactRequest(id: id, fromUserId: from, toUserId: "me", status: .pending, createdAt: Date())
}

private func makeConversation(_ id: String, kind: ConversationKind = .direct, participants: [String] = ["me", "bob"]) -> Conversation {
    Conversation(id: id, kind: kind, title: id, participantIds: participants, lastMessagePreview: nil, updatedAt: Date())
}

@MainActor
final class ContactsViewModelTests: XCTestCase {
    private func makeViewModel(contacts: StubContactRepository, chat: StubChatRepository = StubChatRepository(), users: StubUserRepository) -> ContactsViewModel {
        ContactsViewModel(contactRepository: contacts, chatRepository: chat, userRepository: users)
    }

    func test_load_success_populatesConnectionsAndCounts() async {
        let contacts = StubContactRepository()
        contacts.discoverabilityResult = .success(.nobody)
        contacts.incomingRequestsResult = .success([makeRequest("r1", from: "bob")])
        contacts.myConnectionsResult = .success([makeUser("bob")])
        let users = StubUserRepository()
        users.currentUserResult = .success(makeUser("me"))
        let viewModel = makeViewModel(contacts: contacts, users: users)

        await viewModel.load()

        XCTAssertEqual(viewModel.currentUserId, "me")
        XCTAssertEqual(viewModel.discoverability, .nobody)
        XCTAssertEqual(viewModel.incomingRequestCount, 1)
        XCTAssertEqual(viewModel.connections.map(\.id), ["bob"])
    }

    func test_load_withNoConnections_staysLoadedEmpty() async {
        let users = StubUserRepository()
        users.currentUserResult = .success(makeUser("me"))
        let viewModel = makeViewModel(contacts: StubContactRepository(), users: users)

        await viewModel.load()

        XCTAssertEqual(viewModel.state.value?.count, 0)
    }

    func test_load_failure_setsFailed() async {
        let viewModel = makeViewModel(contacts: StubContactRepository(), users: StubUserRepository())

        await viewModel.load()

        XCTAssertNotNil(viewModel.state.error)
        XCTAssertTrue(viewModel.connections.isEmpty)
    }

    func test_updateDiscoverability_success_updatesValue() async {
        let contacts = StubContactRepository()
        contacts.setDiscoverabilityResult = .success(.contactsOnly)
        let viewModel = makeViewModel(contacts: contacts, users: StubUserRepository())

        await viewModel.updateDiscoverability(.contactsOnly)

        XCTAssertEqual(viewModel.discoverability, .contactsOnly)
    }

    func test_updateDiscoverability_failure_keepsPreviousValue() async {
        let viewModel = makeViewModel(contacts: StubContactRepository(), users: StubUserRepository())

        await viewModel.updateDiscoverability(.nobody)

        XCTAssertEqual(viewModel.discoverability, .everyone)
    }

    func test_simulateIncomingRequest_refreshesRequestCount() async {
        let contacts = StubContactRepository()
        contacts.incomingRequestsResult = .success([makeRequest("r1", from: "a"), makeRequest("r2", from: "b")])
        let viewModel = makeViewModel(contacts: contacts, users: StubUserRepository())

        await viewModel.simulateIncomingRequest()

        XCTAssertEqual(viewModel.incomingRequestCount, 2)
    }

    func test_startChat_success_setsAndClearsNavigation() async {
        let chat = StubChatRepository()
        chat.findOrCreateDirectConversationResult = .success(makeConversation("c9"))
        let viewModel = makeViewModel(contacts: StubContactRepository(), chat: chat, users: StubUserRepository())

        await viewModel.startChat(with: makeUser("bob"))
        XCTAssertEqual(viewModel.navigateToConversationId, "c9")

        viewModel.clearNavigation()
        XCTAssertNil(viewModel.navigateToConversationId)
    }

    func test_startChat_failure_leavesNavigationNil() async {
        let viewModel = makeViewModel(contacts: StubContactRepository(), users: StubUserRepository())

        await viewModel.startChat(with: makeUser("bob"))

        XCTAssertNil(viewModel.navigateToConversationId)
    }
}
