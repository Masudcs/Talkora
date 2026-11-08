import Foundation

/// Wire-format group roster entry; `role` is a `GroupRole` raw value ("member" | "admin" | "owner").
public struct GroupMemberDTO: Codable, Sendable, Hashable {
    public let userId: String
    public let role: String

    public init(userId: String, role: String) {
        self.userId = userId
        self.role = role
    }
}
