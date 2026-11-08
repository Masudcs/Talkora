import Foundation

/// Wire-format representation of a chat message, as a real `/conversations/{id}/messages` response would look.
public struct MessageDTO: Codable, Sendable, Hashable {
    public let id: String
    public let conversationId: String
    public let senderId: String
    public let text: String
    public let createdAt: String
    public let editedAt: String?
    public let replyToMessageId: String?
    public let deliveryState: String
    public let isDeleted: Bool
    public let expiresAt: String?
    public let attachment: MediaAttachmentDTO?
    public let reactions: [ReactionDTO]
    public let paymentTransactionId: String?

    public init(
        id: String,
        conversationId: String,
        senderId: String,
        text: String,
        createdAt: String,
        editedAt: String? = nil,
        replyToMessageId: String? = nil,
        deliveryState: String = "sent",
        isDeleted: Bool = false,
        expiresAt: String? = nil,
        attachment: MediaAttachmentDTO? = nil,
        reactions: [ReactionDTO] = [],
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
}
