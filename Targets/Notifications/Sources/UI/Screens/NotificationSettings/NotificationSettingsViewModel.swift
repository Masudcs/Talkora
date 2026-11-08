import Foundation
import Observation
import UserNotifications
import Core
import Mock

/// Reads and requests notification authorization and runs the demo notification tools through `NotificationScheduling`.
@MainActor
@Observable
final class NotificationSettingsViewModel {
    @ObservationIgnored private var isPreview = false
    /// Mirror of the system status; refreshed in `load()` and after `requestAuthorization()`.
    private(set) var authorizationStatus: UNAuthorizationStatus = .notDetermined
    private(set) var groupConversations: [Conversation] = []
    private(set) var isSimulating = false

    private let chatRepository: IChatRepository
    private let userRepository: IUserRepository
    private let scheduler: NotificationScheduling

    init(chatRepository: IChatRepository = ChatRepository(), userRepository: IUserRepository = UserRepository(), scheduler: NotificationScheduling = NotificationScheduler.shared) {
        self.chatRepository = chatRepository
        self.userRepository = userRepository
        self.scheduler = scheduler
    }

    /// True only for `.authorized`; `.provisional` and `.ephemeral` do not unlock the demo tools.
    var isAuthorized: Bool {
        authorizationStatus == .authorized
    }

    /// Failing to load conversations is not an error here: the group list is just empty.
    func load() async {
        guard !isPreview else { return }
        authorizationStatus = await scheduler.authorizationStatus()
        groupConversations = ((try? await chatRepository.conversations()) ?? []).filter { $0.kind == .group }
    }

    /// Only prompts if the status is still undetermined (`requestAuthorizationIfNeeded`); returns the resulting status.
    func requestAuthorization() async {
        authorizationStatus = await scheduler.requestAuthorizationIfNeeded()
    }

    func sendTestNotification() async {
        await scheduler.sendTestNotification()
    }

    /// Fires a burst of messages in the chosen group, each routed through the same
    /// notification path a real incoming message would take — demonstrating that the
    /// burst collapses into a single digest notification instead of spamming one per message.
    func simulateBusyGroup(_ conversation: Conversation) async {
        isSimulating = true
        defer { isSimulating = false }
        guard let messages = try? await chatRepository.simulateGroupActivity(conversationId: conversation.id) else { return }
        let me = try? await userRepository.currentUser()
        for message in messages {
            let senderName = (try? await userRepository.user(id: message.senderId))?.displayName ?? "Someone"
            let isMention = me.map { message.text.localizedCaseInsensitiveContains($0.handle) } ?? false
            await scheduler.notifyNewMessage(
                conversationId: conversation.id,
                conversationTitle: conversation.title,
                senderName: senderName,
                messageText: message.text,
                isGroup: true,
                isMuted: conversation.isMuted,
                isMention: isMention,
                sound: conversation.notificationSound
            )
        }
    }
}

#if DEBUG
extension NotificationSettingsViewModel {
    convenience init(previewStatus status: UNAuthorizationStatus) {
        self.init(scheduler: PreviewNotificationScheduler(status: status))
        isPreview = true
        authorizationStatus = status
        groupConversations = PreviewData.conversations.filter { $0.kind == .group }
    }
}
#endif
