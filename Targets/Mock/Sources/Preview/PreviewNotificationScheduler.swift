#if DEBUG
import Foundation
import UserNotifications
import Core

/// Stands in for `NotificationScheduler` in `#Preview`s so they never touch
/// `UNUserNotificationCenter`, which isn't available in the preview process.
@MainActor
public final class PreviewNotificationScheduler: NotificationScheduling {
    private var status: UNAuthorizationStatus

    public init(status: UNAuthorizationStatus) {
        self.status = status
    }

    public func authorizationStatus() async -> UNAuthorizationStatus {
        status
    }

    /// Pretends the user granted permission.
    public func requestAuthorizationIfNeeded() async -> UNAuthorizationStatus {
        status = .authorized
        return status
    }

    public func resetDigest(for conversationId: String) {}

    public func notifyNewMessage(
        conversationId: String,
        conversationTitle: String,
        senderName: String,
        messageText: String,
        isGroup: Bool,
        isMuted: Bool,
        isMention: Bool,
        sound: NotificationSound
    ) async {}

    public func notifyMissedCall(callerName: String, conversationId: String, isMuted: Bool) async {}

    public func sendTestNotification() async {}

    public func scheduleReminder(text: String, delay: TimeInterval, conversationId: String) async {}
}
#endif
