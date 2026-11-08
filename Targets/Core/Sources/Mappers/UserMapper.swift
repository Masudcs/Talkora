import Foundation

/// Unknown status values fall back to `.offline`; an unparseable `avatarURL` becomes `nil`.
public extension UserDTO {
    func toDomain() -> User {
        User(
            id: id,
            displayName: displayName,
            handle: handle,
            avatarURL: URL(string: avatarURL),
            status: UserStatus(rawValue: status) ?? .offline,
            createdAt: ISO8601.date(from: createdAt),
            bio: bio,
            isBot: isBot
        )
    }
}
