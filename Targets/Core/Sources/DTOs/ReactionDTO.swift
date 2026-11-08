import Foundation

/// All users who reacted with one emoji on a message.
public struct ReactionDTO: Codable, Sendable, Hashable {
    public let emoji: String
    public let userIds: [String]

    public init(emoji: String, userIds: [String]) {
        self.emoji = emoji
        self.userIds = userIds
    }
}
