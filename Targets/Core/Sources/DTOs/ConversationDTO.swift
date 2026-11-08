import Foundation

/// Wire-format representation of a conversation, as a real `/conversations` response would look.
public struct ConversationDTO: Codable, Sendable, Hashable {
    public let id: String
    public let kind: String // "direct" | "group"
    public let title: String
    public let participantIds: [String]
    public let lastMessagePreview: String?
    public let updatedAt: String
    public let readReceiptsEnabled: Bool
    public let disappearingSeconds: Int?
    public let members: [GroupMemberDTO]
    public let groupDescription: String?
    public let pinnedMessageId: String?
    public let isMuted: Bool
    public let notificationSound: String
    public let wallpaper: String

    public init(
        id: String,
        kind: String,
        title: String,
        participantIds: [String],
        lastMessagePreview: String?,
        updatedAt: String,
        readReceiptsEnabled: Bool = true,
        disappearingSeconds: Int? = nil,
        members: [GroupMemberDTO] = [],
        groupDescription: String? = nil,
        pinnedMessageId: String? = nil,
        isMuted: Bool = false,
        notificationSound: String = "standard",
        wallpaper: String = "default"
    ) {
        self.id = id
        self.kind = kind
        self.title = title
        self.participantIds = participantIds
        self.lastMessagePreview = lastMessagePreview
        self.updatedAt = updatedAt
        self.readReceiptsEnabled = readReceiptsEnabled
        self.disappearingSeconds = disappearingSeconds
        self.members = members
        self.groupDescription = groupDescription
        self.pinnedMessageId = pinnedMessageId
        self.isMuted = isMuted
        self.notificationSound = notificationSound
        self.wallpaper = wallpaper
    }
}
