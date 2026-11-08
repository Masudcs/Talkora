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

@MainActor
final class IncomingRequestsViewModelTests: XCTestCase {
    func test_load_populatesRequestsAndSenderNames() async {
        let contacts = StubContactRepository()
        contacts.incomingRequestsResult = .success([makeRequest("r1", from: "bob")])
        let users = StubUserRepository()
        users.userResult = .success(makeUser("bob", "Bob"))
        let viewModel = IncomingRequestsViewModel(contactRepository: contacts, userRepository: users)

        await viewModel.load()

        XCTAssertEqual(viewModel.requests.map(\.id), ["r1"])
        XCTAssertEqual(viewModel.name(for: viewModel.requests[0]), "Bob")
    }

    func test_load_failure_yieldsNoRequests() async {
        let contacts = StubContactRepository()
        contacts.incomingRequestsResult = .failure(StubFailure.notConfigured)
        let viewModel = IncomingRequestsViewModel(contactRepository: contacts, userRepository: StubUserRepository())

        await viewModel.load()

        XCTAssertTrue(viewModel.requests.isEmpty)
    }

    func test_name_whenSenderLookupFails_isUnknown() async {
        let contacts = StubContactRepository()
        let request = makeRequest("r1", from: "ghost")
        contacts.incomingRequestsResult = .success([request])
        let viewModel = IncomingRequestsViewModel(contactRepository: contacts, userRepository: StubUserRepository())

        await viewModel.load()

        XCTAssertEqual(viewModel.name(for: request), "Unknown")
    }

    func test_respond_accept_removesRequestAndForwardsDecision() async {
        let contacts = StubContactRepository()
        let r1 = makeRequest("r1", from: "a")
        let r2 = makeRequest("r2", from: "b")
        contacts.incomingRequestsResult = .success([r1, r2])
        let viewModel = IncomingRequestsViewModel(contactRepository: contacts, userRepository: StubUserRepository())
        await viewModel.load()

        await viewModel.respond(r1, accept: true)

        XCTAssertEqual(viewModel.requests.map(\.id), ["r2"])
        XCTAssertEqual(contacts.lastRespondAccept, true)
    }

    func test_respond_decline_forwardsDecision() async {
        let contacts = StubContactRepository()
        let r1 = makeRequest("r1", from: "a")
        contacts.incomingRequestsResult = .success([r1])
        let viewModel = IncomingRequestsViewModel(contactRepository: contacts, userRepository: StubUserRepository())
        await viewModel.load()

        await viewModel.respond(r1, accept: false)

        XCTAssertTrue(viewModel.requests.isEmpty)
        XCTAssertEqual(contacts.lastRespondAccept, false)
    }
}
