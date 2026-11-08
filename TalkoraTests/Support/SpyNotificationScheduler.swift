@testable import Talkora
import Foundation
import UserNotifications
@testable import Core

@MainActor
final class SpyNotificationScheduler: NotificationScheduling {
    struct NewMessage: Equatable {
        let conversationId: String
        let senderName: String
        let messageText: String
        let isGroup: Bool
        let isMention: Bool
    }

    var status: UNAuthorizationStatus = .authorized
    var statusAfterRequest: UNAuthorizationStatus = .authorized
    private(set) var requestAuthorizationCount = 0
    private(set) var resetDigestIds: [String] = []
    private(set) var newMessages: [NewMessage] = []
    private(set) var missedCalls: [(callerName: String, conversationId: String)] = []
    private(set) var testNotificationCount = 0
    private(set) var reminders: [(text: String, delay: TimeInterval, conversationId: String)] = []

    func authorizationStatus() async -> UNAuthorizationStatus {
        status
    }

    func requestAuthorizationIfNeeded() async -> UNAuthorizationStatus {
        requestAuthorizationCount += 1
        status = statusAfterRequest
        return status
    }

    func resetDigest(for conversationId: String) {
        resetDigestIds.append(conversationId)
    }

    func notifyNewMessage(
        conversationId: String,
        conversationTitle: String,
        senderName: String,
        messageText: String,
        isGroup: Bool,
        isMuted: Bool,
        isMention: Bool,
        sound: NotificationSound
    ) async {
        newMessages.append(NewMessage(conversationId: conversationId, senderName: senderName, messageText: messageText, isGroup: isGroup, isMention: isMention))
    }

    func notifyMissedCall(callerName: String, conversationId: String, isMuted: Bool) async {
        missedCalls.append((callerName, conversationId))
    }

    func sendTestNotification() async {
        testNotificationCount += 1
    }

    func scheduleReminder(text: String, delay: TimeInterval, conversationId: String) async {
        reminders.append((text, delay, conversationId))
    }
}
