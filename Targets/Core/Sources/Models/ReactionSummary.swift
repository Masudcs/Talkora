import Foundation

/// Aggregated reaction counts for a conversation, built client-side from `Message.reactions`.
public struct EmojiTotal: Identifiable {
    public var id: String { emoji }
    public let emoji: String
    public let count: Int

    public init(emoji: String, count: Int) {
        self.emoji = emoji
        self.count = count
    }
}

/// The most-used emoji and the most-reacted messages of a conversation.
public struct ReactionSummary {
    public let emojiTotals: [EmojiTotal]
    public let topMessages: [Message]

    public init(emojiTotals: [EmojiTotal], topMessages: [Message]) {
        self.emojiTotals = emojiTotals
        self.topMessages = topMessages
    }
}
