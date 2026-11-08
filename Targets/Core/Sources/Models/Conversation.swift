import Foundation

public enum ConversationKind: String, Sendable {
    case direct
    case group
}

/// A chat thread, either a 1:1 `direct` conversation or a `group`.
public struct Conversation: Identifiable, Hashable, Sendable {
    public let id: String
    public let kind: ConversationKind
    public let title: String
    public let participantIds: [String]
    public let lastMessagePreview: String?
    public let updatedAt: Date
    /// Improve: per-conversation (not just one global) read-receipt control.
    public let readReceiptsEnabled: Bool
    /// Uncommon (Telegram): self-destruct timer for new messages in this conversation. Nil = off.
    public let disappearingMessagesDuration: TimeInterval?
    /// Empty for direct conversations; roster + roles for groups.
    public let members: [GroupMember]
    public let groupDescription: String?
    /// Improve: a pinned message gives new members context instead of a wall of history —
    /// admin-only to set in groups, either participant may set it in a direct conversation.
    public let pinnedMessageId: String?
    public let isMuted: Bool
    public let notificationSound: NotificationSound
    public let wallpaper: ChatWallpaper

    public init(
        id: String,
        kind: ConversationKind,
        title: String,
        participantIds: [String],
        lastMessagePreview: String?,
        updatedAt: Date,
        readReceiptsEnabled: Bool = true,
        disappearingMessagesDuration: TimeInterval? = nil,
        members: [GroupMember] = [],
        groupDescription: String? = nil,
        pinnedMessageId: String? = nil,
        isMuted: Bool = false,
        notificationSound: NotificationSound = .standard,
        wallpaper: ChatWallpaper = .default
    ) {
        self.id = id
        self.kind = kind
        self.title = title
        self.participantIds = participantIds
        self.lastMessagePreview = lastMessagePreview
        self.updatedAt = updatedAt
        self.readReceiptsEnabled = readReceiptsEnabled
        self.disappearingMessagesDuration = disappearingMessagesDuration
        self.members = members
        self.groupDescription = groupDescription
        self.pinnedMessageId = pinnedMessageId
        self.isMuted = isMuted
        self.notificationSound = notificationSound
        self.wallpaper = wallpaper
    }

    /// `nil` when the user is not in `members` (always the case for direct conversations).
    public func role(of userId: String) -> GroupRole? {
        members.first { $0.userId == userId }?.role
    }

    public func isAdminOrOwner(_ userId: String) -> Bool {
        role(of: userId) == .admin || role(of: userId) == .owner
    }
}
