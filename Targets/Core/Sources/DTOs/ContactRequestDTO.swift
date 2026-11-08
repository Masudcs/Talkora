import Foundation

/// Wire-format contact request; `status` is a `ContactRequestStatus` raw value ("pending" | "accepted" | "declined").
public struct ContactRequestDTO: Codable, Sendable, Hashable {
    public let id: String
    public let fromUserId: String
    public let toUserId: String
    public let status: String
    public let createdAt: String

    public init(id: String, fromUserId: String, toUserId: String, status: String, createdAt: String) {
        self.id = id
        self.fromUserId = fromUserId
        self.toUserId = toUserId
        self.status = status
        self.createdAt = createdAt
    }
}
