#if DEBUG
import Foundation
import Core

/// Extra sample data for the Search, MediaSharing and Reactions previews.
public extension PreviewData {
    private static var otherUserId: String {
        users.first { $0.id != currentUser.id }?.id ?? currentUser.id
    }

    /// Text and attachment messages for the direct conversation, newest first.
    static var searchMessages: [Message] {
        let conversationId = directConversation.id
        let now = Date()
        return [
            Message(id: "pv-s1", conversationId: conversationId, senderId: otherUserId, text: "Here's the spot we talked about", createdAt: now.addingTimeInterval(-3_600)),
            Message(id: "pv-s2", conversationId: conversationId, senderId: currentUser.id, text: "Sounds good, see you at 6 at the spot", createdAt: now.addingTimeInterval(-86_400)),
            Message(
                id: "pv-s3", conversationId: conversationId, senderId: otherUserId, text: "", createdAt: now.addingTimeInterval(-172_800),
                attachment: MediaAttachment(id: "pv-att1", kind: .image, fileName: "IMG_0142.jpg", sizeBytes: 920_000, quality: .compressed, url: URL(string: "https://picsum.photos/seed/asset1/800"), durationSeconds: nil)
            ),
        ]
    }

    /// Search results built from the sample conversations, messages and users.
    static var globalSearchResults: GlobalSearchResults {
        let conversationId = directConversation.id
        let title = directConversation.title
        return GlobalSearchResults(
            conversations: Array(conversations.prefix(2)),
            messages: searchMessages.map { MessageSearchHit(message: $0, conversationId: conversationId, conversationTitle: title) },
            users: Array(users.filter { $0.id != currentUser.id }.prefix(3))
        )
    }

    /// Messages carrying attachments, for the Media & Files grid.
    static var mediaHistoryMessages: [Message] {
        let conversationId = directConversation.id
        let now = Date()
        let attachments: [MediaAttachment] = [
            MediaAttachment(id: "pv-m1", kind: .image, fileName: "IMG_0142.jpg", sizeBytes: 920_000, quality: .compressed, url: URL(string: "https://picsum.photos/seed/asset1/800"), durationSeconds: nil),
            MediaAttachment(id: "pv-m2", kind: .image, fileName: "IMG_0158.jpg", sizeBytes: 840_000, quality: .compressed, url: URL(string: "https://picsum.photos/seed/asset2/800"), durationSeconds: nil),
            MediaAttachment(id: "pv-m3", kind: .video, fileName: "IMG_0177.mov", sizeBytes: 9_000_000, quality: .compressed, url: URL(string: "https://picsum.photos/seed/asset5/800"), durationSeconds: 18),
            MediaAttachment(id: "pv-m4", kind: .file, fileName: "Budget.xlsx", sizeBytes: 210_000, quality: .original, url: nil, durationSeconds: nil),
        ]
        return attachments.enumerated().map { index, attachment in
            Message(id: "pv-mh\(index)", conversationId: conversationId, senderId: index.isMultiple(of: 2) ? otherUserId : currentUser.id, text: "", createdAt: now.addingTimeInterval(-Double(index) * 86_400), attachment: attachment)
        }
    }

    /// Hand-built totals; they are not derived from `topMessages`.
    static var reactionSummary: ReactionSummary {
        let conversationId = groupConversation.id
        let ids = users.map(\.id)
        let first = ids.first ?? currentUser.id
        let second = ids.dropFirst().first ?? first
        let now = Date()
        let top = [
            Message(id: "pv-r1", conversationId: conversationId, senderId: first, text: "I'll bring the tent", createdAt: now.addingTimeInterval(-3_600), reactions: [MessageReaction(emoji: "👍", userIds: [first, second]), MessageReaction(emoji: "🔥", userIds: [first])]),
            Message(id: "pv-r2", conversationId: conversationId, senderId: second, text: "Who's driving up on Friday?", createdAt: now.addingTimeInterval(-7_200), reactions: [MessageReaction(emoji: "😂", userIds: [second])]),
        ]
        return ReactionSummary(
            emojiTotals: [EmojiTotal(emoji: "👍", count: 8), EmojiTotal(emoji: "😂", count: 5), EmojiTotal(emoji: "🔥", count: 2)],
            topMessages: top
        )
    }
}
#endif
