import Foundation

public enum UserStatus: String, Sendable {
    case online
    case offline
    case away
}

public struct User: Identifiable, Hashable, Sendable {
    public let id: String
    public let displayName: String
    public let handle: String
    public let avatarURL: URL?
    public let status: UserStatus
    public let createdAt: Date
    public let bio: String
    /// Improve: bot messages are visually distinguished (a banner + tinted bubbles in
    /// `ChatThreadScreen`), not indistinguishable from a human participant.
    public let isBot: Bool

    public init(id: String, displayName: String, handle: String, avatarURL: URL?, status: UserStatus, createdAt: Date, bio: String = "", isBot: Bool = false) {
        self.id = id
        self.displayName = displayName
        self.handle = handle
        self.avatarURL = avatarURL
        self.status = status
        self.createdAt = createdAt
        self.bio = bio
        self.isBot = isBot
    }
}
