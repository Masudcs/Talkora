@testable import Talkora
import Foundation
@testable import Core

final class StubChatRepository: IChatRepository {
    var conversationsResult: Result<[Conversation], Error> = .success([])
    var conversationResult: Result<Conversation, Error> = .failure(StubFailure.notConfigured)
    var messagesResult: Result<Page<Message>, Error> = .success(Page(items: [], nextCursor: nil, hasMore: false))
    var sendMessageResult: Result<Message, Error> = .failure(StubFailure.notConfigured)
    var editMessageResult: Result<Message, Error> = .failure(StubFailure.notConfigured)
    var deleteMessageResult: Result<Void, Error> = .success(())
    var markViewOnceConsumedResult: Result<Message, Error> = .failure(StubFailure.notConfigured)
    var updateSettingsResult: Result<Conversation, Error> = .failure(StubFailure.notConfigured)
    var simulateDeliveryTicksResult: Result<Message, Error> = .failure(StubFailure.notConfigured)
    var simulateIncomingReplyResult: Result<Message, Error> = .failure(StubFailure.notConfigured)
    var setMutedResult: Result<Conversation, Error> = .failure(StubFailure.notConfigured)
    var setPinnedMessageResult: Result<Conversation, Error> = .failure(StubFailure.notConfigured)
    var createGroupResult: Result<Conversation, Error> = .failure(StubFailure.notConfigured)
    var addMemberResult: Result<Conversation, Error> = .failure(StubFailure.notConfigured)
    var removeMemberResult: Result<Conversation, Error> = .failure(StubFailure.notConfigured)
    var updateMemberRoleResult: Result<Conversation, Error> = .failure(StubFailure.notConfigured)
    var updateGroupInfoResult: Result<Conversation, Error> = .failure(StubFailure.notConfigured)
    var findOrCreateDirectConversationResult: Result<Conversation, Error> = .failure(StubFailure.notConfigured)
    var toggleReactionResult: Result<Message, Error> = .failure(StubFailure.notConfigured)
    var setNotificationSoundResult: Result<Conversation, Error> = .failure(StubFailure.notConfigured)
    var setWallpaperResult: Result<Conversation, Error> = .failure(StubFailure.notConfigured)
    var simulateGroupActivityResult: Result<[Message], Error> = .success([])

    func conversations() async throws -> [Conversation] {
        try conversationsResult.get()
    }

    func conversation(id: String) async throws -> Conversation {
        try conversationResult.get()
    }

    func messages(conversationId: String, cursor: String?) async throws -> Page<Message> {
        try messagesResult.get()
    }

    func sendMessage(text: String, conversationId: String, replyToMessageId: String?) async throws -> Message {
        try sendMessageResult.get()
    }

    func editMessage(messageId: String, conversationId: String, newText: String) async throws -> Message {
        try editMessageResult.get()
    }

    func deleteMessage(messageId: String, conversationId: String) async throws {
        try deleteMessageResult.get()
    }

    func markViewOnceConsumed(messageId: String, conversationId: String) async throws -> Message {
        try markViewOnceConsumedResult.get()
    }

    func updateSettings(conversationId: String, readReceiptsEnabled: Bool, disappearingDuration: TimeInterval?) async throws -> Conversation {
        try updateSettingsResult.get()
    }

    func simulateDeliveryTicks(messageId: String, conversationId: String) async throws -> Message {
        try simulateDeliveryTicksResult.get()
    }

    func simulateIncomingReply(conversationId: String) async throws -> Message {
        try simulateIncomingReplyResult.get()
    }

    func setMuted(_ muted: Bool, for conversationId: String) async throws -> Conversation {
        try setMutedResult.get()
    }

    func setPinnedMessage(_ messageId: String?, in conversationId: String) async throws -> Conversation {
        try setPinnedMessageResult.get()
    }

    func createGroup(title: String, description: String?, memberIds: [String]) async throws -> Conversation {
        try createGroupResult.get()
    }

    func addMember(_ userId: String, to conversationId: String) async throws -> Conversation {
        try addMemberResult.get()
    }

    func removeMember(_ userId: String, from conversationId: String) async throws -> Conversation {
        try removeMemberResult.get()
    }

    func updateMemberRole(_ userId: String, role: GroupRole, in conversationId: String) async throws -> Conversation {
        try updateMemberRoleResult.get()
    }

    func updateGroupInfo(conversationId: String, title: String, description: String?) async throws -> Conversation {
        try updateGroupInfoResult.get()
    }

    func findOrCreateDirectConversation(with userId: String) async throws -> Conversation {
        try findOrCreateDirectConversationResult.get()
    }

    func toggleReaction(_ emoji: String, messageId: String, conversationId: String) async throws -> Message {
        try toggleReactionResult.get()
    }

    func setNotificationSound(_ sound: NotificationSound, for conversationId: String) async throws -> Conversation {
        try setNotificationSoundResult.get()
    }

    func setWallpaper(_ wallpaper: ChatWallpaper, for conversationId: String) async throws -> Conversation {
        try setWallpaperResult.get()
    }

    func simulateGroupActivity(conversationId: String) async throws -> [Message] {
        try simulateGroupActivityResult.get()
    }
}
