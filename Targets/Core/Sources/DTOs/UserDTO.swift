import Foundation

/// Wire-format representation of a user, exactly as a real `/users/{id}` response would look.
public struct UserDTO: Codable, Sendable, Hashable {
    public let id: String
    public let displayName: String
    public let handle: String
    public let avatarURL: String
    public let status: String
    public let createdAt: String
    public let bio: String
    public let isBot: Bool

    public init(id: String, displayName: String, handle: String, avatarURL: String, status: String, createdAt: String, bio: String = "", isBot: Bool = false) {
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
