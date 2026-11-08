import Foundation

/// Current user and user lookup/profile edits.
public enum UserRoutes: EndpointConvertible {
    case me
    case user(id: String)
    case allUsers
    case updateProfile(userId: String, displayName: String, bio: String, avatarURL: String?)

    public var endpoint: Endpoint {
        switch self {
        case .me:
            return Endpoint(path: "/me")
        case .user(let id):
            return Endpoint(path: "/users/\(id)")
        case .allUsers:
            return Endpoint(path: "/users")
        case .updateProfile(let userId, let displayName, let bio, let avatarURL):
            return Endpoint(path: "/users/\(userId)", method: .patch, body: ProfileBody(displayName: displayName, bio: bio, avatarURL: avatarURL))
        }
    }
}

// MARK: - Request bodies

public extension UserRoutes {
    struct ProfileBody: Encodable, Sendable { let displayName: String; let bio: String; let avatarURL: String? }
}
