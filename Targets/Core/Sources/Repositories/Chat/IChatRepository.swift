import Foundation

/// The full chat surface. ViewModels depend on the narrowest protocol they need
/// (`IConversationRepository`, `IMessageRepository` or `IGroupRepository`).
public protocol IChatRepository: IConversationRepository, IMessageRepository, IGroupRepository {}

public protocol IConversationRepository: Sendable {
    func conversations() async throws -> [Conversation]
    func conversation(id: String) async throws -> Conversation
    /// Backs "message this contact" from Contacts/Discovery — returns the existing 1:1
    /// conversation if one already exists, otherwise creates it.
    func findOrCreateDirectConversation(with userId: String) async throws -> Conversation
    func updateSettings(conversationId: String, readReceiptsEnabled: Bool, disappearingDuration: TimeInterval?) async throws -> Conversation
    func setMuted(_ muted: Bool, for conversationId: String) async throws -> Conversation
    func setPinnedMessage(_ messageId: String?, in conversationId: String) async throws -> Conversation
    func setNotificationSound(_ sound: NotificationSound, for conversationId: String) async throws -> Conversation
    /// Improve: a per-chat wallpaper, same idea as WhatsApp's, without needing real image upload —
    /// a fixed set of gradients is enough for a mock backend.
    func setWallpaper(_ wallpaper: ChatWallpaper, for conversationId: String) async throws -> Conversation
}

public protocol IMessageRepository: Sendable {
    /// Pass the previous page's `nextCursor` to load the next page; `nil` starts at the beginning.
    func messages(conversationId: String, cursor: String?) async throws -> Page<Message>
    func sendMessage(text: String, conversationId: String, replyToMessageId: String?) async throws -> Message
    func editMessage(messageId: String, conversationId: String, newText: String) async throws -> Message
    func deleteMessage(messageId: String, conversationId: String) async throws
    /// Uncommon (WhatsApp): marks a view-once attachment consumed the first time it's opened —
    /// permanent for everyone, not just the viewer.
    func markViewOnceConsumed(messageId: String, conversationId: String) async throws -> Message
    /// Toggles the current user's own reaction with this emoji — independent of any
    /// other emoji they've already reacted with on the same message.
    func toggleReaction(_ emoji: String, messageId: String, conversationId: String) async throws -> Message

    /// The next two model server-push events a real client would receive over a socket
    /// (delivery receipts, a contact's reply) rather than a request/response call — but
    /// since this mock backend has no live transport, they're exposed as endpoints the
    /// ViewModel polls for once, right after sending, to animate ticks/typing/reply.
    func simulateDeliveryTicks(messageId: String, conversationId: String) async throws -> Message
    func simulateIncomingReply(conversationId: String) async throws -> Message
    /// Demo affordance for Module 8: fires a burst of messages from several group members
    /// at once, so notification bundling/digest behavior has something to bundle.
    func simulateGroupActivity(conversationId: String) async throws -> [Message]
}

/// Group management. The backend only lets admins and owners add members, change roles and edit group info; any member can remove themselves.
public protocol IGroupRepository: Sendable {
    func createGroup(title: String, description: String?, memberIds: [String]) async throws -> Conversation
    func addMember(_ userId: String, to conversationId: String) async throws -> Conversation
    func removeMember(_ userId: String, from conversationId: String) async throws -> Conversation
    func updateMemberRole(_ userId: String, role: GroupRole, in conversationId: String) async throws -> Conversation
    func updateGroupInfo(conversationId: String, title: String, description: String?) async throws -> Conversation
}
