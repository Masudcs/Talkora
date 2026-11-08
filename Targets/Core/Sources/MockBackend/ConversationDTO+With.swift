import Foundation

/// "PATCH-style" convenience for `MockDataStore` mutations: omit a parameter to leave that
/// field unchanged. Fields where `nil` is itself a meaningful value to set (clearing a
/// description, unpinning a message) take a double-optional — pass `.some(nil)` to
/// explicitly clear, or omit entirely to leave untouched.
public extension ConversationDTO {
    func with(
        title: String? = nil,
        participantIds: [String]? = nil,
        lastMessagePreview: String?? = nil,
        updatedAt: String? = nil,
        readReceiptsEnabled: Bool? = nil,
        disappearingSeconds: Int?? = nil,
        members: [GroupMemberDTO]? = nil,
        groupDescription: String?? = nil,
        pinnedMessageId: String?? = nil,
        isMuted: Bool? = nil,
        notificationSound: String? = nil,
        wallpaper: String? = nil
    ) -> ConversationDTO {
        ConversationDTO(
            id: id,
            kind: kind,
            title: title ?? self.title,
            participantIds: participantIds ?? self.participantIds,
            lastMessagePreview: lastMessagePreview ?? self.lastMessagePreview,
            updatedAt: updatedAt ?? self.updatedAt,
            readReceiptsEnabled: readReceiptsEnabled ?? self.readReceiptsEnabled,
            disappearingSeconds: disappearingSeconds ?? self.disappearingSeconds,
            members: members ?? self.members,
            groupDescription: groupDescription ?? self.groupDescription,
            pinnedMessageId: pinnedMessageId ?? self.pinnedMessageId,
            isMuted: isMuted ?? self.isMuted,
            notificationSound: notificationSound ?? self.notificationSound,
            wallpaper: wallpaper ?? self.wallpaper
        )
    }
}
