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
final class SearchUsersViewModelTests: XCTestCase {
    func test_search_withBlankQuery_clearsResultsWithoutCallingRepository() async {
        let contacts = StubContactRepository()
        let viewModel = SearchUsersViewModel(contactRepository: contacts)
        viewModel.query = "   "

        await viewModel.search()

        XCTAssertTrue(viewModel.results.isEmpty)
        XCTAssertNil(contacts.lastSearchQuery)
    }

    func test_search_success_populatesResults() async {
        let contacts = StubContactRepository()
        contacts.searchUsersResult = .success([makeUser("bob")])
        let viewModel = SearchUsersViewModel(contactRepository: contacts)
        viewModel.query = "bo"

        await viewModel.search()

        XCTAssertEqual(viewModel.results.map(\.id), ["bob"])
        XCTAssertEqual(contacts.lastSearchQuery, "bo")
        XCTAssertFalse(viewModel.isSearching)
    }

    func test_search_failure_yieldsEmptyResults() async {
        let contacts = StubContactRepository()
        contacts.searchUsersResult = .failure(StubFailure.notConfigured)
        let viewModel = SearchUsersViewModel(contactRepository: contacts)
        viewModel.query = "bo"

        await viewModel.search()

        XCTAssertTrue(viewModel.results.isEmpty)
        XCTAssertFalse(viewModel.isSearching)
    }

    func test_sendRequest_success_recordsSentUser() async {
        let contacts = StubContactRepository()
        contacts.sendContactRequestResult = .success(makeRequest("r1", from: "me"))
        let viewModel = SearchUsersViewModel(contactRepository: contacts)

        await viewModel.sendRequest(to: makeUser("bob"))

        XCTAssertEqual(viewModel.sentRequestUserIds, ["bob"])
        XCTAssertNil(viewModel.requestError)
    }

    func test_sendRequest_failure_setsError() async {
        let viewModel = SearchUsersViewModel(contactRepository: StubContactRepository())

        await viewModel.sendRequest(to: makeUser("bob"))

        XCTAssertTrue(viewModel.sentRequestUserIds.isEmpty)
        XCTAssertNotNil(viewModel.requestError)
    }
}
