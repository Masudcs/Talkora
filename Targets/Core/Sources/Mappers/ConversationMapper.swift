import Foundation

/// Unknown enum-like values fall back to defaults (`.direct`, `.member`, `.standard` sound, `.default` wallpaper). `disappearingSeconds` becomes `disappearingMessagesDuration`, and `nil` means the timer is off.
public extension ConversationDTO {
    func toDomain() -> Conversation {
        Conversation(
            id: id,
            kind: ConversationKind(rawValue: kind) ?? .direct,
            title: title,
            participantIds: participantIds,
            lastMessagePreview: lastMessagePreview,
            updatedAt: ISO8601.date(from: updatedAt),
            readReceiptsEnabled: readReceiptsEnabled,
            disappearingMessagesDuration: disappearingSeconds.map(TimeInterval.init),
            members: members.map { GroupMember(userId: $0.userId, role: GroupRole(rawValue: $0.role) ?? .member) },
            groupDescription: groupDescription,
            pinnedMessageId: pinnedMessageId,
            isMuted: isMuted,
            notificationSound: NotificationSound(rawValue: notificationSound) ?? .standard,
            wallpaper: ChatWallpaper(rawValue: wallpaper) ?? .default
        )
    }
}
