@testable import Talkora
import Foundation
import XCTest
@testable import Core
@testable import MediaSharing

private func makeMessage(_ id: String, text: String = "", attachment: MediaAttachment? = nil) -> Message {
    Message(id: id, conversationId: "conv1", senderId: "me", text: text, createdAt: Date(), attachment: attachment)
}

private func makeAttachment(_ id: String, fileName: String) -> MediaAttachment {
    MediaAttachment(id: id, kind: .image, fileName: fileName, sizeBytes: 100, quality: .compressed, url: nil, durationSeconds: nil)
}

@MainActor
final class MediaHistoryViewModelTests: XCTestCase {
    func test_load_success_setsLoadedState() async {
        let stub = StubMediaRepository()
        stub.mediaHistoryResult = .success([makeMessage("m1", attachment: makeAttachment("a1", fileName: "cat.png"))])
        let viewModel = MediaHistoryViewModel(conversationId: "conv1", repository: stub)

        await viewModel.load()

        XCTAssertEqual(viewModel.state.value?.map(\.id), ["m1"])
    }

    func test_load_empty_setsEmptyState() async {
        let viewModel = MediaHistoryViewModel(conversationId: "conv1", repository: StubMediaRepository())

        await viewModel.load()

        guard case .empty = viewModel.state else { return XCTFail("expected empty, got \(viewModel.state)") }
    }

    func test_load_failure_setsFailedState() async {
        let stub = StubMediaRepository()
        stub.mediaHistoryResult = .failure(StubFailure.notConfigured)
        let viewModel = MediaHistoryViewModel(conversationId: "conv1", repository: stub)

        await viewModel.load()

        XCTAssertNotNil(viewModel.state.error)
    }

    func test_filteredItems_emptyQuery_returnsAll() async {
        let stub = StubMediaRepository()
        stub.mediaHistoryResult = .success([
            makeMessage("m1", attachment: makeAttachment("a1", fileName: "cat.png")),
            makeMessage("m2", attachment: makeAttachment("a2", fileName: "dog.png"))
        ])
        let viewModel = MediaHistoryViewModel(conversationId: "conv1", repository: stub)
        await viewModel.load()

        XCTAssertEqual(viewModel.filteredItems.count, 2)
    }

    func test_filteredItems_matchesFileNameCaseInsensitively() async {
        let stub = StubMediaRepository()
        stub.mediaHistoryResult = .success([
            makeMessage("m1", attachment: makeAttachment("a1", fileName: "Cat.png")),
            makeMessage("m2", attachment: makeAttachment("a2", fileName: "dog.png"))
        ])
        let viewModel = MediaHistoryViewModel(conversationId: "conv1", repository: stub)
        await viewModel.load()

        viewModel.searchQuery = "cat"

        XCTAssertEqual(viewModel.filteredItems.map(\.id), ["m1"])
    }

    func test_filteredItems_matchesCaptionText() async {
        let stub = StubMediaRepository()
        stub.mediaHistoryResult = .success([
            makeMessage("m1", text: "holiday trip", attachment: makeAttachment("a1", fileName: "a.png")),
            makeMessage("m2", text: "other", attachment: makeAttachment("a2", fileName: "b.png"))
        ])
        let viewModel = MediaHistoryViewModel(conversationId: "conv1", repository: stub)
        await viewModel.load()

        viewModel.searchQuery = "holiday"

        XCTAssertEqual(viewModel.filteredItems.map(\.id), ["m1"])
    }

    func test_filteredItems_excludesMessagesWithoutAttachmentWhenSearching() async {
        let stub = StubMediaRepository()
        stub.mediaHistoryResult = .success([makeMessage("m1", text: "cat")])
        let viewModel = MediaHistoryViewModel(conversationId: "conv1", repository: stub)
        await viewModel.load()

        viewModel.searchQuery = "cat"

        XCTAssertTrue(viewModel.filteredItems.isEmpty)
    }
}
