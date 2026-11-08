@testable import Talkora
import Foundation
import XCTest
@testable import Core
@testable import Messaging

private func makeMessage(_ id: String, text: String = "", attachment: MediaAttachment? = nil) -> Message {
    Message(id: id, conversationId: "conv1", senderId: "me", text: text, createdAt: Date(), attachment: attachment)
}

@MainActor
private func waitUntil(timeout: TimeInterval = 3, _ condition: () -> Bool) async {
    let deadline = Date().addingTimeInterval(timeout)
    while !condition() && Date() < deadline {
        try? await Task.sleep(nanoseconds: 20_000_000)
    }
}

@MainActor
final class InChatSearchViewModelTests: XCTestCase {
    func test_query_blank_clearsResultsAndIsNotSearching() {
        let viewModel = InChatSearchViewModel(conversationId: "conv1", repository: StubSearchRepository())
        viewModel.query = "  "

        XCTAssertTrue(viewModel.results.isEmpty)
        XCTAssertFalse(viewModel.isSearching)
    }

    func test_query_nonBlank_setsIsSearchingImmediately() {
        let viewModel = InChatSearchViewModel(conversationId: "conv1", repository: StubSearchRepository())
        viewModel.query = "hello"

        XCTAssertTrue(viewModel.isSearching)
    }

    func test_mediaOnly_enabledWithBlankQuery_setsIsSearching() {
        let viewModel = InChatSearchViewModel(conversationId: "conv1", repository: StubSearchRepository())
        viewModel.mediaOnly = true

        XCTAssertTrue(viewModel.isSearching)
    }

    func test_query_nonBlank_afterDebounce_publishesResults() async {
        let stub = StubSearchRepository()
        stub.searchMessagesResult = .success([makeMessage("m1", text: "hello")])
        let viewModel = InChatSearchViewModel(conversationId: "conv1", repository: stub)

        viewModel.query = "hello"
        await waitUntil { !viewModel.isSearching }

        XCTAssertEqual(viewModel.results.map(\.id), ["m1"])
    }

    func test_query_clearedAfterSearch_resetsResults() async {
        let stub = StubSearchRepository()
        stub.searchMessagesResult = .success([makeMessage("m1", text: "hello")])
        let viewModel = InChatSearchViewModel(conversationId: "conv1", repository: stub)
        viewModel.query = "hello"
        await waitUntil { !viewModel.isSearching }

        viewModel.query = ""

        XCTAssertTrue(viewModel.results.isEmpty)
        XCTAssertFalse(viewModel.isSearching)
    }
}
