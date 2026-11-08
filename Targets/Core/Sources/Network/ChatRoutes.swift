import Foundation

/// Conversations, messages, reactions, per-chat settings and group management. The `simulate*` cases are demo-only hooks that exist on the mock backend to fake incoming activity. Message paging goes through `requestPage` on `.messages`, which adds `cursor` and `pageSize` query items.
public enum ChatRoutes: EndpointConvertible {
    case conversations
    case conversation(id: String)
    case directConversation(userId: String)
    case messages(conversationId: String)
    case sendMessage(conversationId: String, text: String, replyToMessageId: String?)
    case editMessage(conversationId: String, messageId: String, text: String)
    case deleteMessage(conversationId: String, messageId: String)
    case consumeViewOnce(conversationId: String, messageId: String)
    case toggleReaction(conversationId: String, messageId: String, emoji: String)
    case updateSettings(conversationId: String, readReceiptsEnabled: Bool, disappearingSeconds: Int)
    case simulateDeliveryTicks(conversationId: String, messageId: String)
    case simulateReply(conversationId: String)
    case setMuted(conversationId: String, muted: Bool)
    case setPinnedMessage(conversationId: String, messageId: String?)
    case setNotificationSound(conversationId: String, sound: String)
    case setWallpaper(conversationId: String, wallpaper: String)
    case simulateGroupActivity(conversationId: String)
    case createGroup(title: String, description: String?, memberIds: [String])
    case addMember(conversationId: String, userId: String)
    case removeMember(conversationId: String, userId: String)
    case updateMemberRole(conversationId: String, userId: String, role: String)
    case updateGroupInfo(conversationId: String, title: String, description: String?)

    public var endpoint: Endpoint {
        switch self {
        case .conversations:
            return Endpoint(path: "/conversations")
        case .conversation(let id):
            return Endpoint(path: "/conversations/\(id)")
        case .directConversation(let userId):
            return Endpoint(path: "/conversations/direct", method: .post, body: UserIdBody(userId: userId))
        case .messages(let conversationId):
            return Endpoint(path: "/conversations/\(conversationId)/messages")
        case .sendMessage(let conversationId, let text, let replyToMessageId):
            return Endpoint(path: "/conversations/\(conversationId)/messages", method: .post,
                            body: SendMessageBody(text: text, replyToMessageId: replyToMessageId))
        case .editMessage(let conversationId, let messageId, let text):
            return Endpoint(path: "/conversations/\(conversationId)/messages/\(messageId)", method: .patch, body: TextBody(text: text))
        case .deleteMessage(let conversationId, let messageId):
            return Endpoint(path: "/conversations/\(conversationId)/messages/\(messageId)", method: .delete)
        case .consumeViewOnce(let conversationId, let messageId):
            return Endpoint(path: "/conversations/\(conversationId)/messages/\(messageId)/consume-view-once", method: .post)
        case .toggleReaction(let conversationId, let messageId, let emoji):
            return Endpoint(path: "/conversations/\(conversationId)/messages/\(messageId)/reactions", method: .post, body: ReactionBody(emoji: emoji))
        case .updateSettings(let conversationId, let readReceiptsEnabled, let disappearingSeconds):
            return Endpoint(path: "/conversations/\(conversationId)/settings", method: .put,
                            body: SettingsBody(readReceiptsEnabled: readReceiptsEnabled, disappearingSeconds: disappearingSeconds))
        case .simulateDeliveryTicks(let conversationId, let messageId):
            return Endpoint(path: "/conversations/\(conversationId)/messages/\(messageId)/delivery-simulate", method: .post)
        case .simulateReply(let conversationId):
            return Endpoint(path: "/conversations/\(conversationId)/simulate-reply", method: .post)
        case .setMuted(let conversationId, let muted):
            return Endpoint(path: "/conversations/\(conversationId)/mute", method: .put, body: MuteBody(muted: muted))
        case .setPinnedMessage(let conversationId, let messageId):
            return Endpoint(path: "/conversations/\(conversationId)/pin", method: .put, body: PinBody(messageId: messageId))
        case .setNotificationSound(let conversationId, let sound):
            return Endpoint(path: "/conversations/\(conversationId)/notification-sound", method: .put, body: SoundBody(sound: sound))
        case .setWallpaper(let conversationId, let wallpaper):
            return Endpoint(path: "/conversations/\(conversationId)/wallpaper", method: .put, body: WallpaperBody(wallpaper: wallpaper))
        case .simulateGroupActivity(let conversationId):
            return Endpoint(path: "/conversations/\(conversationId)/simulate-group-activity", method: .post)
        case .createGroup(let title, let description, let memberIds):
            return Endpoint(path: "/groups", method: .post, body: CreateGroupBody(title: title, description: description, memberIds: memberIds))
        case .addMember(let conversationId, let userId):
            return Endpoint(path: "/conversations/\(conversationId)/members", method: .post, body: UserIdBody(userId: userId))
        case .removeMember(let conversationId, let userId):
            return Endpoint(path: "/conversations/\(conversationId)/members/\(userId)", method: .delete)
        case .updateMemberRole(let conversationId, let userId, let role):
            return Endpoint(path: "/conversations/\(conversationId)/members/\(userId)", method: .patch, body: RoleBody(role: role))
        case .updateGroupInfo(let conversationId, let title, let description):
            return Endpoint(path: "/conversations/\(conversationId)/info", method: .patch, body: GroupInfoBody(title: title, description: description))
        }
    }
}

// MARK: - Request bodies

/// Encodable request bodies for these routes.
public extension ChatRoutes {
    struct UserIdBody: Encodable, Sendable { let userId: String }
    struct TextBody: Encodable, Sendable { let text: String }
    struct SendMessageBody: Encodable, Sendable { let text: String; let replyToMessageId: String? }
    struct ReactionBody: Encodable, Sendable { let emoji: String }
    struct SettingsBody: Encodable, Sendable { let readReceiptsEnabled: Bool; let disappearingSeconds: Int }
    struct MuteBody: Encodable, Sendable { let muted: Bool }
    struct PinBody: Encodable, Sendable { let messageId: String? }
    struct SoundBody: Encodable, Sendable { let sound: String }
    struct WallpaperBody: Encodable, Sendable { let wallpaper: String }
    struct CreateGroupBody: Encodable, Sendable { let title: String; let description: String?; let memberIds: [String] }
    struct RoleBody: Encodable, Sendable { let role: String }
    struct GroupInfoBody: Encodable, Sendable { let title: String; let description: String? }
}
