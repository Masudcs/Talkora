import Foundation

/// Blanks the text of a deleted message so a tombstone never shows leftover content. Unknown delivery states fall back to `.sent`.
public extension MessageDTO {
    func toDomain() -> Message {
        Message(
            id: id,
            conversationId: conversationId,
            senderId: senderId,
            text: isDeleted ? "" : text,
            createdAt: ISO8601.date(from: createdAt),
            editedAt: editedAt.map(ISO8601.date(from:)),
            replyToMessageId: replyToMessageId,
            deliveryState: MessageDeliveryState(rawValue: deliveryState) ?? .sent,
            isDeleted: isDeleted,
            expiresAt: expiresAt.map(ISO8601.date(from:)),
            attachment: attachment?.toDomain(),
            reactions: reactions.map { MessageReaction(emoji: $0.emoji, userIds: $0.userIds) },
            paymentTransactionId: paymentTransactionId
        )
    }
}

/// Unknown kinds fall back to `.file` and unknown qualities to `.original`; a malformed `url` becomes `nil`.
public extension MediaAttachmentDTO {
    func toDomain() -> MediaAttachment {
        MediaAttachment(
            id: id,
            kind: MediaKind(rawValue: kind) ?? .file,
            fileName: fileName,
            sizeBytes: sizeBytes,
            quality: MediaQuality(rawValue: quality) ?? .original,
            url: url.flatMap(URL.init(string:)),
            durationSeconds: durationSeconds,
            isViewOnce: isViewOnce,
            isConsumed: isConsumed
        )
    }
}
