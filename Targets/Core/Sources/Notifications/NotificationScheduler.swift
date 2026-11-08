import Foundation
import UserNotifications

/// Registered with `UNUserNotificationCenter`; message notifications use it to carry the quick-reply action.
public enum NotificationCategory: String {
    case message = "MESSAGE"
}

public enum NotificationActionIdentifier: String {
    case quickReply = "QUICK_REPLY"
}

/// What ViewModels need from the notification layer. Lets tests inject a recording fake
/// instead of touching `UNUserNotificationCenter`.
@MainActor
public protocol NotificationScheduling: AnyObject {
    func authorizationStatus() async -> UNAuthorizationStatus
    @discardableResult
    func requestAuthorizationIfNeeded() async -> UNAuthorizationStatus
    func resetDigest(for conversationId: String)
    func notifyNewMessage(
        conversationId: String,
        conversationTitle: String,
        senderName: String,
        messageText: String,
        isGroup: Bool,
        isMuted: Bool,
        isMention: Bool,
        sound: NotificationSound
    ) async
    func notifyMissedCall(callerName: String, conversationId: String, isMuted: Bool) async
    func sendTestNotification() async
    func scheduleReminder(text: String, delay: TimeInterval, conversationId: String) async
}

/// Wraps `UNUserNotificationCenter` to deliver real local notification banners — this is a
/// genuine iOS capability, not a fake in-app overlay, even though the "server" behind it is
/// entirely mock. A singleton because `UNUserNotificationCenter` itself is process-wide.
///
/// Improve: rapid-fire group activity is bundled into one summary notification instead of
/// one-per-message spam (`pendingDigestCounts`), and message notifications carry a quick-reply
/// text action so you can respond straight from the banner/lock screen without opening the app.
@MainActor
public final class NotificationScheduler: NSObject, NotificationScheduling {
    public static let shared = NotificationScheduler()

    /// Set once at launch by the composition root — lets a quick-reply banner action actually
    /// send the message, without this service needing a direct dependency on `IChatRepository`.
    public var onQuickReply: ((_ text: String, _ conversationId: String) async -> Void)?

    private let center = UNUserNotificationCenter.current()
    private var pendingDigestCounts: [String: Int] = [:]

    private override init() {
        super.init()
        center.delegate = self
        registerCategories()
    }

    private func registerCategories() {
        let replyAction = UNTextInputNotificationAction(
            identifier: NotificationActionIdentifier.quickReply.rawValue,
            title: "Reply",
            options: [],
            textInputButtonTitle: "Send",
            textInputPlaceholder: "Message…"
        )
        let messageCategory = UNNotificationCategory(
            identifier: NotificationCategory.message.rawValue,
            actions: [replyAction],
            intentIdentifiers: [],
            options: []
        )
        center.setNotificationCategories([messageCategory])
    }

    public func authorizationStatus() async -> UNAuthorizationStatus {
        await center.notificationSettings().authorizationStatus
    }

    @discardableResult
    public func requestAuthorizationIfNeeded() async -> UNAuthorizationStatus {
        let current = await authorizationStatus()
        if current == .notDetermined {
            _ = try? await center.requestAuthorization(options: [.alert, .sound, .badge])
        }
        return await authorizationStatus()
    }

    /// Called when a conversation's thread is opened, so a fresh burst of activity later
    /// starts a new digest count rather than continuing to add to a stale one.
    public func resetDigest(for conversationId: String) {
        pendingDigestCounts[conversationId] = nil
    }

    public func notifyNewMessage(
        conversationId: String,
        conversationTitle: String,
        senderName: String,
        messageText: String,
        isGroup: Bool,
        isMuted: Bool,
        isMention: Bool,
        sound: NotificationSound
    ) async {
        guard !isMuted, await authorizationStatus() == .authorized else { return }

        let content = UNMutableNotificationContent()
        content.threadIdentifier = conversationId
        content.categoryIdentifier = NotificationCategory.message.rawValue
        content.sound = sound == .silent ? nil : .default
        content.userInfo = ["conversationId": conversationId]

        let bodyText = isMention ? "Mentioned you: \(messageText)" : messageText

        if isGroup {
            // Improve: bundle a burst of group messages into one summary notification —
            // iOS's `threadIdentifier` already stacks them visually; this additionally
            // rewrites the pending notification's content so it reads as one digest.
            let count = (pendingDigestCounts[conversationId] ?? 0) + 1
            pendingDigestCounts[conversationId] = count
            content.title = conversationTitle
            content.body = count > 1 ? "\(count) new messages" : "\(senderName): \(bodyText)"
            await add(UNNotificationRequest(identifier: "digest-\(conversationId)", content: content, trigger: nil))
        } else {
            content.title = senderName
            content.body = bodyText
            await add(UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil))
        }
    }

    public func notifyMissedCall(callerName: String, conversationId: String, isMuted: Bool) async {
        guard !isMuted, await authorizationStatus() == .authorized else { return }
        let content = UNMutableNotificationContent()
        content.title = "Missed Call"
        content.body = "\(callerName) called you"
        content.sound = .default
        content.threadIdentifier = conversationId
        await add(UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil))
    }

    public func sendTestNotification() async {
        let content = UNMutableNotificationContent()
        content.title = "Talkora"
        content.body = "This is a test notification."
        content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        await add(UNNotificationRequest(identifier: "test-notification", content: content, trigger: trigger))
    }

    /// Module 15's Reminder Bot proof-of-automation: a genuinely scheduled local
    /// notification, not just a canned chat reply pretending to be one.
    public func scheduleReminder(text: String, delay: TimeInterval, conversationId: String) async {
        guard await authorizationStatus() == .authorized else { return }
        let content = UNMutableNotificationContent()
        content.title = "⏰ Reminder"
        content.body = text
        content.sound = .default
        content.threadIdentifier = conversationId
        content.userInfo = ["conversationId": conversationId]
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: delay, repeats: false)
        await add(UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger))
    }

    private func add(_ request: UNNotificationRequest) async {
        await withCheckedContinuation { continuation in
            center.add(request) { _ in
                continuation.resume()
            }
        }
    }
}

extension NotificationScheduler: UNUserNotificationCenterDelegate {
    /// Always show the banner even in the foreground — otherwise there'd be no way to see
    /// this demo's notifications without backgrounding the app.
    public nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound, .list])
    }

    public nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        if response.actionIdentifier == NotificationActionIdentifier.quickReply.rawValue,
           let textResponse = response as? UNTextInputNotificationResponse,
           let conversationId = response.notification.request.content.userInfo["conversationId"] as? String {
            let text = textResponse.userText
            Task { @MainActor in
                await NotificationScheduler.shared.onQuickReply?(text, conversationId)
            }
        }
        completionHandler()
    }
}
