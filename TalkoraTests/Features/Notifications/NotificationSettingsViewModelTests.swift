@testable import Talkora
import Foundation
import UserNotifications
import XCTest
@testable import Core
@testable import Notifications

@MainActor
final class NotificationSettingsViewModelTests: XCTestCase {
    private func makeUser(_ id: String, _ name: String, handle: String) -> User {
        User(id: id, displayName: name, handle: handle, avatarURL: nil, status: .online, createdAt: Date())
    }

    private func makeConversation(_ id: String, kind: ConversationKind) -> Conversation {
        Conversation(id: id, kind: kind, title: id, participantIds: ["me", "bob"], lastMessagePreview: nil, updatedAt: Date())
    }

    private func makeViewModel(chat: StubChatRepository = StubChatRepository(), users: StubUserRepository = StubUserRepository(), scheduler: SpyNotificationScheduler) -> NotificationSettingsViewModel {
        NotificationSettingsViewModel(chatRepository: chat, userRepository: users, scheduler: scheduler)
    }

    func test_load_readsAuthorizationStatusAndKeepsOnlyGroups() async {
        let scheduler = SpyNotificationScheduler()
        scheduler.status = .denied
        let chat = StubChatRepository()
        chat.conversationsResult = .success([makeConversation("g1", kind: .group), makeConversation("d1", kind: .direct)])
        let viewModel = makeViewModel(chat: chat, scheduler: scheduler)

        await viewModel.load()

        XCTAssertEqual(viewModel.authorizationStatus, .denied)
        XCTAssertFalse(viewModel.isAuthorized)
        XCTAssertEqual(viewModel.groupConversations.map(\.id), ["g1"])
    }

    func test_requestAuthorization_updatesStatusFromScheduler() async {
        let scheduler = SpyNotificationScheduler()
        scheduler.status = .notDetermined
        scheduler.statusAfterRequest = .authorized
        let viewModel = makeViewModel(scheduler: scheduler)

        await viewModel.requestAuthorization()

        XCTAssertEqual(scheduler.requestAuthorizationCount, 1)
        XCTAssertTrue(viewModel.isAuthorized)
    }

    func test_sendTestNotification_forwardsToScheduler() async {
        let scheduler = SpyNotificationScheduler()
        let viewModel = makeViewModel(scheduler: scheduler)

        await viewModel.sendTestNotification()

        XCTAssertEqual(scheduler.testNotificationCount, 1)
    }

    func test_simulateBusyGroup_notifiesOncePerMessageAndFlagsMentions() async {
        let scheduler = SpyNotificationScheduler()
        let chat = StubChatRepository()
        chat.simulateGroupActivityResult = .success([
            Message(id: "m1", conversationId: "g1", senderId: "bob", text: "hello", createdAt: Date()),
            Message(id: "m2", conversationId: "g1", senderId: "bob", text: "hey @me look", createdAt: Date())
        ])
        let users = StubUserRepository()
        users.currentUserResult = .success(makeUser("me", "Me", handle: "@me"))
        users.userResult = .success(makeUser("bob", "Bob", handle: "@bob"))
        let viewModel = makeViewModel(chat: chat, users: users, scheduler: scheduler)

        await viewModel.simulateBusyGroup(makeConversation("g1", kind: .group))

        XCTAssertEqual(scheduler.newMessages.map(\.messageText), ["hello", "hey @me look"])
        XCTAssertEqual(scheduler.newMessages.map(\.isMention), [false, true])
        XCTAssertTrue(scheduler.newMessages.allSatisfy { $0.isGroup && $0.senderName == "Bob" })
        XCTAssertFalse(viewModel.isSimulating)
    }

    func test_simulateBusyGroup_whenActivityFails_notifiesNothing() async {
        let scheduler = SpyNotificationScheduler()
        let chat = StubChatRepository()
        chat.simulateGroupActivityResult = .failure(StubFailure.notConfigured)
        let viewModel = makeViewModel(chat: chat, scheduler: scheduler)

        await viewModel.simulateBusyGroup(makeConversation("g1", kind: .group))

        XCTAssertTrue(scheduler.newMessages.isEmpty)
        XCTAssertFalse(viewModel.isSimulating)
    }
}
