@testable import Talkora
import Foundation
import XCTest
@testable import Core
@testable import Messaging

@MainActor
final class ChatThreadViewModelTests: XCTestCase {
    private let me = User(id: "u1", displayName: "You", handle: "@me", avatarURL: nil, status: .online, createdAt: Date())
    private let other = User(id: "u2", displayName: "Amara Chen", handle: "@amara", avatarURL: nil, status: .online, createdAt: Date())

    private func makeConversation() -> Conversation {
        Conversation(id: "c1", kind: .direct, title: "Amara Chen", participantIds: ["u1", "u2"], lastMessagePreview: nil, updatedAt: Date())
    }

    private func makeViewModel(chatStub: StubChatRepository, userStub: StubUserRepository) -> ChatThreadViewModel {
        userStub.currentUserResult = .success(me)
        userStub.userResult = .success(other)
        chatStub.conversationResult = .success(makeConversation())
        return ChatThreadViewModel(conversationId: "c1", chatRepository: chatStub, userRepository: userStub,
                                   privacyRepository: StubPrivacyRepository(), paymentRepository: StubPaymentRepository(), botRepository: StubBotRepository())
    }

    func test_load_populatesConversationAndMessages() async {
        let chatStub = StubChatRepository()
        let message = Message(id: "m1", conversationId: "c1", senderId: "u2", text: "Hi", createdAt: Date())
        chatStub.messagesResult = .success(Page(items: [message], nextCursor: nil, hasMore: false))
        let viewModel = makeViewModel(chatStub: chatStub, userStub: StubUserRepository())

        await viewModel.load()

        XCTAssertEqual(viewModel.currentUserId, "u1")
        XCTAssertEqual(viewModel.otherParticipant?.id, "u2")
        XCTAssertEqual(viewModel.messages.count, 1)
    }

    func test_send_appendsMessageOptimistically() async {
        let chatStub = StubChatRepository()
        chatStub.messagesResult = .success(Page(items: [], nextCursor: nil, hasMore: false))
        let sent = Message(id: "new", conversationId: "c1", senderId: "u1", text: "Hello", createdAt: Date())
        chatStub.sendMessageResult = .success(sent)
        let viewModel = makeViewModel(chatStub: chatStub, userStub: StubUserRepository())
        await viewModel.load()

        viewModel.draftText = "Hello"
        await viewModel.send()

        XCTAssertTrue(viewModel.messages.contains { $0.id == "new" })
        XCTAssertEqual(viewModel.draftText, "")
    }

    func test_beginEdit_ignoredForMessageFromOtherParticipant() async {
        let chatStub = StubChatRepository()
        chatStub.messagesResult = .success(Page(items: [], nextCursor: nil, hasMore: false))
        let viewModel = makeViewModel(chatStub: chatStub, userStub: StubUserRepository())
        await viewModel.load()
        let theirMessage = Message(id: "m1", conversationId: "c1", senderId: "u2", text: "Hi", createdAt: Date())

        viewModel.beginEdit(theirMessage)

        XCTAssertFalse(viewModel.isEditing)
    }

    func test_beginEdit_allowedForOwnRecentMessage() async {
        let chatStub = StubChatRepository()
        chatStub.messagesResult = .success(Page(items: [], nextCursor: nil, hasMore: false))
        let viewModel = makeViewModel(chatStub: chatStub, userStub: StubUserRepository())
        await viewModel.load()
        let myMessage = Message(id: "m1", conversationId: "c1", senderId: "u1", text: "Hi", createdAt: Date())

        viewModel.beginEdit(myMessage)

        XCTAssertTrue(viewModel.isEditing)
        XCTAssertEqual(viewModel.draftText, "Hi")
    }
}
