import Foundation

/// Conversations, messages and groups, over `APIClientProtocol` — behaves the same against the mock, stubbed and live backends.
public final class ChatRepository: IChatRepository {
    private let api: APIClientProtocol

    public init(api: APIClientProtocol = APIClientProvider.shared.client) {
        self.api = api
    }

    public func conversations() async throws -> [Conversation] {
        let dtos: [ConversationDTO] = try await api.request(ChatRoutes.conversations)
        return dtos.map { $0.toDomain() }
    }

    public func conversation(id: String) async throws -> Conversation {
        let dto: ConversationDTO = try await api.request(ChatRoutes.conversation(id: id))
        return dto.toDomain()
    }

    public func findOrCreateDirectConversation(with userId: String) async throws -> Conversation {
        let dto: ConversationDTO = try await api.request(
            ChatRoutes.directConversation(userId: userId)
        )
        return dto.toDomain()
    }

    public func messages(conversationId: String, cursor: String?) async throws -> Page<Message> {
        let page: Page<MessageDTO> = try await api.requestPage(
            ChatRoutes.messages(conversationId: conversationId),
            cursor: cursor,
            pageSize: 30
        )
        return Page(items: page.items.map { $0.toDomain() }, nextCursor: page.nextCursor, hasMore: page.hasMore)
    }

    public func sendMessage(text: String, conversationId: String, replyToMessageId: String?) async throws -> Message {
        let dto: MessageDTO = try await api.request(
            ChatRoutes.sendMessage(conversationId: conversationId, text: text, replyToMessageId: replyToMessageId)
        )
        return dto.toDomain()
    }

    public func editMessage(messageId: String, conversationId: String, newText: String) async throws -> Message {
        let dto: MessageDTO = try await api.request(
            ChatRoutes.editMessage(conversationId: conversationId, messageId: messageId, text: newText)
        )
        return dto.toDomain()
    }

    public func deleteMessage(messageId: String, conversationId: String) async throws {
        try await api.requestVoid(
            ChatRoutes.deleteMessage(conversationId: conversationId, messageId: messageId)
        )
    }

    public func markViewOnceConsumed(messageId: String, conversationId: String) async throws -> Message {
        let dto: MessageDTO = try await api.request(
            ChatRoutes.consumeViewOnce(conversationId: conversationId, messageId: messageId)
        )
        return dto.toDomain()
    }

    public func toggleReaction(_ emoji: String, messageId: String, conversationId: String) async throws -> Message {
        let dto: MessageDTO = try await api.request(
            ChatRoutes.toggleReaction(conversationId: conversationId, messageId: messageId, emoji: emoji)
        )
        return dto.toDomain()
    }

    public func updateSettings(conversationId: String, readReceiptsEnabled: Bool, disappearingDuration: TimeInterval?) async throws -> Conversation {
        let dto: ConversationDTO = try await api.request(
            ChatRoutes.updateSettings(
                conversationId: conversationId,
                readReceiptsEnabled: readReceiptsEnabled,
                disappearingSeconds: disappearingDuration.map { Int($0) } ?? 0
            )
        )
        return dto.toDomain()
    }

    public func simulateDeliveryTicks(messageId: String, conversationId: String) async throws -> Message {
        let dto: MessageDTO = try await api.request(
            ChatRoutes.simulateDeliveryTicks(conversationId: conversationId, messageId: messageId)
        )
        return dto.toDomain()
    }

    public func simulateIncomingReply(conversationId: String) async throws -> Message {
        let dto: MessageDTO = try await api.request(
            ChatRoutes.simulateReply(conversationId: conversationId)
        )
        return dto.toDomain()
    }

    public func setMuted(_ muted: Bool, for conversationId: String) async throws -> Conversation {
        let dto: ConversationDTO = try await api.request(
            ChatRoutes.setMuted(conversationId: conversationId, muted: muted)
        )
        return dto.toDomain()
    }

    public func setPinnedMessage(_ messageId: String?, in conversationId: String) async throws -> Conversation {
        let dto: ConversationDTO = try await api.request(
            ChatRoutes.setPinnedMessage(conversationId: conversationId, messageId: messageId)
        )
        return dto.toDomain()
    }

    public func setNotificationSound(_ sound: NotificationSound, for conversationId: String) async throws -> Conversation {
        let dto: ConversationDTO = try await api.request(
            ChatRoutes.setNotificationSound(conversationId: conversationId, sound: sound.rawValue)
        )
        return dto.toDomain()
    }

    public func setWallpaper(_ wallpaper: ChatWallpaper, for conversationId: String) async throws -> Conversation {
        let dto: ConversationDTO = try await api.request(
            ChatRoutes.setWallpaper(conversationId: conversationId, wallpaper: wallpaper.rawValue)
        )
        return dto.toDomain()
    }

    public func simulateGroupActivity(conversationId: String) async throws -> [Message] {
        let dtos: [MessageDTO] = try await api.request(
            ChatRoutes.simulateGroupActivity(conversationId: conversationId)
        )
        return dtos.map { $0.toDomain() }
    }

    public func createGroup(title: String, description: String?, memberIds: [String]) async throws -> Conversation {
        let dto: ConversationDTO = try await api.request(
            ChatRoutes.createGroup(title: title, description: description, memberIds: memberIds)
        )
        return dto.toDomain()
    }

    public func addMember(_ userId: String, to conversationId: String) async throws -> Conversation {
        let dto: ConversationDTO = try await api.request(
            ChatRoutes.addMember(conversationId: conversationId, userId: userId)
        )
        return dto.toDomain()
    }

    public func removeMember(_ userId: String, from conversationId: String) async throws -> Conversation {
        try await api.requestVoid(
            ChatRoutes.removeMember(conversationId: conversationId, userId: userId)
        )
        return try await conversation(id: conversationId)
    }

    public func updateMemberRole(_ userId: String, role: GroupRole, in conversationId: String) async throws -> Conversation {
        let dto: ConversationDTO = try await api.request(
            ChatRoutes.updateMemberRole(conversationId: conversationId, userId: userId, role: role.rawValue)
        )
        return dto.toDomain()
    }

    public func updateGroupInfo(conversationId: String, title: String, description: String?) async throws -> Conversation {
        let dto: ConversationDTO = try await api.request(
            ChatRoutes.updateGroupInfo(conversationId: conversationId, title: title, description: description)
        )
        return dto.toDomain()
    }
}
