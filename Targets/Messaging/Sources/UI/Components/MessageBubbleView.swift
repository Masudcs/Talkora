import SwiftUI
import Core
import CommonUI

/// One message in the thread. Pure presentation: the parent computes all flags (`isMine`, mentions,
/// reply target, payment) and receives user actions through closures.
/// Renders, in priority order: deleted tombstone, payment card, attachment (+ optional caption), plain text.
struct MessageBubbleView: View {
    let message: Message
    let isMine: Bool
    let currentUserId: String
    let senderName: String?
    let isMentioningMe: Bool
    let repliedMessage: Message?
    let canPin: Bool
    let isPinned: Bool
    let onReply: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    let onTogglePin: () -> Void
    let onViewOnceTap: () -> Void
    let onReact: () -> Void
    let onToggleReaction: (String) -> Void
    let payment: PaymentTransaction?
    let onRespondToPayment: (Bool) -> Void
    let isBotSender: Bool

    var body: some View {
        HStack {
            if isMine { Spacer(minLength: 48) }
            VStack(alignment: isMine ? .trailing : .leading, spacing: 4) {
                if let senderName {
                    Text(senderName)
                        .font(.caption.bold())
                        .foregroundStyle(Color.accentColor)
                }
                if let repliedMessage {
                    ReplyPreview(message: repliedMessage)
                }
                bubble
                if !message.isDeleted {
                    ReactionBarView(reactions: message.reactions, currentUserId: currentUserId, onToggle: onToggleReaction)
                }
                HStack(spacing: 4) {
                    if isPinned {
                        Image(systemName: "pin.fill")
                            .font(.caption2)
                            .foregroundStyle(Color.secondary)
                    }
                    if message.editedAt != nil, !message.isDeleted {
                        Text("Edited")
                            .font(.caption2)
                            .foregroundStyle(Color.secondary)
                    }
                    Text(message.createdAt, style: .time)
                        .font(.caption2)
                        .foregroundStyle(Color.secondary)
                    if isMine, !message.isDeleted {
                        DeliveryTicks(state: message.deliveryState)
                    }
                }
            }
            if !isMine { Spacer(minLength: 48) }
        }
        .contextMenu {
            if !message.isDeleted {
                Button("React", systemImage: "face.smiling", action: onReact)
                Button("Reply", systemImage: "arrowshape.turn.up.left", action: onReply)
                if canPin {
                    Button(isPinned ? "Unpin" : "Pin", systemImage: "pin", action: onTogglePin)
                }
                if isMine, message.canEditOrDelete {
                    Button("Edit", systemImage: "pencil", action: onEdit)
                    Button("Delete", systemImage: "trash", role: .destructive, action: onDelete)
                }
            }
        }
    }

    @ViewBuilder
    private var bubble: some View {
        if message.isDeleted {
            Text("This message was deleted")
                .italic()
                .font(Font.body)
                .foregroundStyle(Color.secondary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(bubbleBackground)
                .clipShape(RoundedRectangle(cornerRadius: 16))
        } else if message.paymentTransactionId != nil {
            PaymentMessageCard(text: message.text, payment: payment, currentUserId: currentUserId, onRespond: onRespondToPayment)
        } else if let attachment = message.attachment {
            VStack(alignment: .leading, spacing: 0) {
                if attachment.isViewOnce {
                    ViewOncePlaceholder(isConsumed: attachment.isConsumed, onTap: onViewOnceTap)
                } else {
                    MediaAttachmentView(attachment: attachment)
                }
                if !message.text.isEmpty {
                    Text(message.text)
                        .font(Font.body)
                        .foregroundStyle(isMine ? .white : Color.primary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                }
            }
            .background(message.text.isEmpty ? Color.clear : bubbleBackground)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(mentionBorder)
        } else {
            Text(message.text)
                .font(Font.body)
                .foregroundStyle(isMine ? .white : Color.primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(bubbleBackground)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(mentionBorder)
        }
    }

    private var mentionBorder: some View {
        RoundedRectangle(cornerRadius: 16)
            .strokeBorder(isMentioningMe ? Color.accentColor : .clear, lineWidth: 2)
    }

    /// Precedence: own message, bot sender, mention highlight, default.
    private var bubbleBackground: Color {
        if isMine { return Color.accentColor }
        if isBotSender { return Color.purple.opacity(0.15) }
        return isMentioningMe ? Color.accentColor.opacity(0.12) : Color(.secondarySystemBackground)
    }
}

private struct ReplyPreview: View {
    let message: Message

    var body: some View {
        Text(message.isDeleted ? "This message was deleted" : message.text)
            .font(.caption)
            .foregroundStyle(Color.secondary)
            .lineLimit(1)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color(.secondarySystemBackground).opacity(0.6))
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

/// One tick for `.sent`, two for delivered/read; accent-colored only when read.
private struct DeliveryTicks: View {
    let state: MessageDeliveryState

    var body: some View {
        HStack(spacing: -4) {
            Image(systemName: "checkmark")
            if state != .sent {
                Image(systemName: "checkmark")
            }
        }
        .font(.system(size: 9, weight: .bold))
        .foregroundStyle(state == .read ? Color.accentColor : Color.secondary)
    }
}

/// Stands in for a view-once attachment; disabled once consumed so it can't be reopened.
private struct ViewOncePlaceholder: View {
    let isConsumed: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                Image(systemName: isConsumed ? "eye.slash.fill" : "1.circle.fill")
                    .font(.system(size: 28))
                Text(isConsumed ? "Opened" : "View Once")
                    .font(.caption.bold())
            }
            .foregroundStyle(.white)
            .frame(width: 200, height: 200)
            .background(isConsumed ? Color.gray : Color.accentColor)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .disabled(isConsumed)
    }
}
