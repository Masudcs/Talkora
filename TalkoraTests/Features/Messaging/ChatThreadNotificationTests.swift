@testable import Talkora
import Foundation
import UserNotifications
import XCTest
@testable import Core
@testable import Messaging

@MainActor
final class ChatThreadNotificationTests: XCTestCase {
    func test_load_resetsNotificationDigestForTheConversation() async {
        let me = User(id: "u1", displayName: "You", handle: "@me", avatarURL: nil, status: .online, createdAt: Date())
        let other = User(id: "u2", displayName: "Amara", handle: "@amara", avatarURL: nil, status: .online, createdAt: Date())
        let chat = StubChatRepository()
        chat.conversationResult = .success(Conversation(id: "c1", kind: .direct, title: "Amara", participantIds: ["u1", "u2"], lastMessagePreview: nil, updatedAt: Date()))
        chat.messagesResult = .success(Page(items: [Message(id: "m1", conversationId: "c1", senderId: "u2", text: "Hi", createdAt: Date())], nextCursor: nil, hasMore: false))
        let users = StubUserRepository()
        users.currentUserResult = .success(me)
        users.userResult = .success(other)
        let scheduler = SpyNotificationScheduler()
        let viewModel = ChatThreadViewModel(
            conversationId: "c1", chatRepository: chat, userRepository: users,
            privacyRepository: StubPrivacyRepository(), paymentRepository: StubPaymentRepository(),
            botRepository: StubBotRepository(), scheduler: scheduler
        )

        await viewModel.load()

        XCTAssertEqual(scheduler.resetDigestIds, ["c1"])
    }
}
