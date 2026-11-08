@testable import Talkora
import Foundation
import XCTest
@testable import Core
@testable import Messaging

private func makeUser(_ id: String, handle: String? = nil) -> User {
    User(id: id, displayName: id.capitalized, handle: handle ?? "@\(id)", avatarURL: nil, status: .online, createdAt: Date())
}

@MainActor
private func waitUntil(timeout: TimeInterval = 3, _ condition: () -> Bool) async {
    let deadline = Date().addingTimeInterval(timeout)
    while !condition() && Date() < deadline {
        try? await Task.sleep(nanoseconds: 20_000_000)
    }
}

@MainActor
final class GlobalSearchViewModelTests: XCTestCase {
    func test_trimmedQuery_stripsWhitespace() {
        let viewModel = GlobalSearchViewModel(repository: StubSearchRepository(), chatRepository: StubChatRepository())
        viewModel.query = "  hello \n"
        XCTAssertEqual(viewModel.trimmedQuery, "hello")
    }

    func test_query_blank_clearsResultsAndIsNotSearching() {
        let viewModel = GlobalSearchViewModel(repository: StubSearchRepository(), chatRepository: StubChatRepository())
        viewModel.query = "   "

        XCTAssertTrue(viewModel.results.isEmpty)
        XCTAssertFalse(viewModel.isSearching)
    }

    func test_query_nonBlank_setsIsSearchingImmediately() {
        let viewModel = GlobalSearchViewModel(repository: StubSearchRepository(), chatRepository: StubChatRepository())
        viewModel.query = "hello"

        XCTAssertTrue(viewModel.isSearching)
    }

    func test_query_nonBlank_afterDebounce_publishesResults() async {
        let stub = StubSearchRepository()
        stub.globalSearchResult = .success(GlobalSearchResults(conversations: [], messages: [], users: [makeUser("bob")]))
        let viewModel = GlobalSearchViewModel(repository: stub, chatRepository: StubChatRepository())

        viewModel.query = "bob"
        await waitUntil { !viewModel.isSearching }

        XCTAssertEqual(viewModel.results.users.map(\.id), ["bob"])
        XCTAssertEqual(stub.lastGlobalQuery, "bob")
    }

    func test_query_clearedAfterSearch_resetsResults() async {
        let stub = StubSearchRepository()
        stub.globalSearchResult = .success(GlobalSearchResults(conversations: [], messages: [], users: [makeUser("bob")]))
        let viewModel = GlobalSearchViewModel(repository: stub, chatRepository: StubChatRepository())
        viewModel.query = "bob"
        await waitUntil { !viewModel.isSearching }

        viewModel.query = ""

        XCTAssertTrue(viewModel.results.isEmpty)
        XCTAssertFalse(viewModel.isSearching)
    }
}
