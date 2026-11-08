import Foundation

public enum GroupRole: String, Sendable {
    case member
    case admin
    case owner
}

public struct GroupMember: Identifiable, Hashable, Sendable {
    public let userId: String
    public let role: GroupRole
    public var id: String { userId }

    public init(userId: String, role: GroupRole) {
        self.userId = userId
        self.role = role
    }
}
