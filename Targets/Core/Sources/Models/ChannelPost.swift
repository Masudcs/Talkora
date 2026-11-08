import Foundation

/// A post in a broadcast channel; only channel owners and admins can create them.
public struct ChannelPost: Identifiable, Hashable, Sendable {
    public let id: String
    public let channelId: String
    public let authorId: String
    public let text: String
    public let createdAt: Date
    public let viewCount: Int

    public init(id: String, channelId: String, authorId: String, text: String, createdAt: Date, viewCount: Int) {
        self.id = id
        self.channelId = channelId
        self.authorId = authorId
        self.text = text
        self.createdAt = createdAt
        self.viewCount = viewCount
    }
}
