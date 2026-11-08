@testable import Talkora
import Foundation
import XCTest
@testable import Core
@testable import Reactions

@MainActor
final class ReactionAnalyticsViewModelTests: XCTestCase {
    func test_load_aggregatesEmojiTotalsAndTopMessages() async {
        let stub = StubChatRepository()
        let reacted = Message(id: "m1", conversationId: "c1", senderId: "u1", text: "Hi", createdAt: Date(),
                              reactions: [MessageReaction(emoji: "👍", userIds: ["a", "b"]), MessageReaction(emoji: "❤️", userIds: ["a"])])
        let plain = Message(id: "m2", conversationId: "c1", senderId: "u1", text: "Yo", createdAt: Date())
        stub.messagesResult = .success(Page(items: [reacted, plain], nextCursor: nil, hasMore: false))
        let viewModel = ReactionAnalyticsViewModel(conversationId: "c1", chatRepository: stub)

        await viewModel.load()

        let summary = viewModel.state.value
        XCTAssertEqual(summary?.emojiTotals.first?.emoji, "👍")
        XCTAssertEqual(summary?.emojiTotals.first?.count, 2)
        XCTAssertEqual(summary?.topMessages.map(\.id), ["m1"])
    }

    func test_load_withNoReactions_setsEmpty() async {
        let viewModel = ReactionAnalyticsViewModel(conversationId: "c1", chatRepository: StubChatRepository())

        await viewModel.load()

        guard case .empty = viewModel.state else { return XCTFail("expected .empty, got \(viewModel.state)") }
    }

    func test_load_failure_setsFailed() async {
        let stub = StubChatRepository()
        stub.messagesResult = .failure(StubFailure.notConfigured)
        let viewModel = ReactionAnalyticsViewModel(conversationId: "c1", chatRepository: stub)

        await viewModel.load()

        XCTAssertNotNil(viewModel.state.error)
    }
}
