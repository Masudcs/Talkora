import Foundation

/// Tick progression shown in the bubble: `sent`, then `delivered`, then `read`.
public enum MessageDeliveryState: String, Sendable {
    case sent
    case delivered
    case read
}

/// Improve: the reaction set is open-ended (any emoji via the system keyboard), not a
/// fixed tapback-style palette of 6-7 — grouped per emoji so a bubble can show "👍 3"
/// without listing every reactor inline.
public struct MessageReaction: Identifiable, Hashable, Sendable {
    public var id: String { emoji }
    public let emoji: String
    public let userIds: [String]

    public init(emoji: String, userIds: [String]) {
        self.emoji = emoji
        self.userIds = userIds
    }
}

/// A single chat message. A deleted message stays in the list as a tombstone (`isDeleted`, empty text).
public struct Message: Identifiable, Hashable, Sendable {
    /// Same window governs both edit and unsend, unlike WhatsApp's differing rules —
    /// one clear cutoff instead of ad-hoc per-action limits.
    public static let editUnsendWindow: TimeInterval = 15 * 60

    public let id: String
    public let conversationId: String
    public let senderId: String
    public let text: String
    public let createdAt: Date
    public let editedAt: Date?
    public let replyToMessageId: String?
    public let deliveryState: MessageDeliveryState
    public let isDeleted: Bool
    public let expiresAt: Date?
    public let attachment: MediaAttachment?
    public let reactions: [MessageReaction]
    /// Set when this message represents a P2P payment (send/request) rather than
    /// regular text — `ChatThreadViewModel` resolves it to a `PaymentTransaction`.
    public let paymentTransactionId: String?

    public init(
        id: String,
        conversationId: String,
        senderId: String,
        text: String,
        createdAt: Date,
        editedAt: Date? = nil,
        replyToMessageId: String? = nil,
        deliveryState: MessageDeliveryState = .sent,
        isDeleted: Bool = false,
        expiresAt: Date? = nil,
        attachment: MediaAttachment? = nil,
        reactions: [MessageReaction] = [],
        paymentTransactionId: String? = nil
    ) {
        self.id = id
        self.conversationId = conversationId
        self.senderId = senderId
        self.text = text
        self.createdAt = createdAt
        self.editedAt = editedAt
        self.replyToMessageId = replyToMessageId
        self.deliveryState = deliveryState
        self.isDeleted = isDeleted
        self.expiresAt = expiresAt
        self.attachment = attachment
        self.reactions = reactions
        self.paymentTransactionId = paymentTransactionId
    }

    public var canEditOrDelete: Bool {
        !isDeleted && Date().timeIntervalSince(createdAt) <= Self.editUnsendWindow
    }
}

