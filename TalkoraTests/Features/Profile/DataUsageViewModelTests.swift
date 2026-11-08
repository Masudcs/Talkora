@testable import Talkora
import Foundation
import XCTest
@testable import Core
@testable import Profile

@MainActor
final class DataUsageViewModelTests: XCTestCase {
    private func makeConversation(_ id: String) -> Conversation {
        Conversation(id: id, kind: .direct, title: id, participantIds: ["me", "bob"], lastMessagePreview: nil, updatedAt: Date())
    }

    private func makeMediaMessage(_ id: String, kind: MediaKind, bytes: Int) -> Message {
        let attachment = MediaAttachment(id: "a\(id)", kind: kind, fileName: "f", sizeBytes: bytes, quality: .original, url: nil, durationSeconds: nil)
        return Message(id: id, conversationId: "c1", senderId: "me", text: "", createdAt: Date(), attachment: attachment)
    }

    private func makeViewModel(chat: StubChatRepository, media: StubMediaRepository) -> DataUsageViewModel {
        DataUsageViewModel(chatRepository: chat, mediaRepository: media, userRepository: StubUserRepository())
    }

    func test_load_aggregatesBytesPerKindSortedBySize() async {
        let chat = StubChatRepository()
        chat.conversationsResult = .success([makeConversation("c1")])
        let media = StubMediaRepository()
        media.mediaHistoryResult = .success([
            makeMediaMessage("m1", kind: .image, bytes: 100),
            makeMediaMessage("m2", kind: .video, bytes: 500),
            makeMediaMessage("m3", kind: .image, bytes: 50)
        ])
        let viewModel = makeViewModel(chat: chat, media: media)

        await viewModel.load()

        XCTAssertEqual(viewModel.statsState.value?.map(\.label), ["Videos", "Photos"])
        XCTAssertEqual(viewModel.statsState.value?.map(\.bytes), [500, 150])
        XCTAssertEqual(viewModel.totalBytes, 650)
    }

    func test_load_withNoMedia_setsEmpty() async {
        let chat = StubChatRepository()
        chat.conversationsResult = .success([makeConversation("c1")])
        let viewModel = makeViewModel(chat: chat, media: StubMediaRepository())

        await viewModel.load()

        guard case .empty = viewModel.statsState else { return XCTFail("expected .empty, got \(viewModel.statsState)") }
        XCTAssertEqual(viewModel.totalBytes, 0)
    }

    func test_load_whenConversationsFail_setsFailed() async {
        let chat = StubChatRepository()
        chat.conversationsResult = .failure(StubFailure.notConfigured)
        let viewModel = makeViewModel(chat: chat, media: StubMediaRepository())

        await viewModel.load()

        XCTAssertNotNil(viewModel.statsState.error)
    }
}
