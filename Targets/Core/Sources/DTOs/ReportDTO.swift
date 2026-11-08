import Foundation

/// A user report stored by the mock backend. Nothing reads reports back, so there is no domain model or mapper for it.
public struct ReportDTO: Codable, Sendable, Hashable {
    public let id: String
    public let reportedUserId: String
    public let reason: String
    public let createdAt: String

    public init(id: String, reportedUserId: String, reason: String, createdAt: String) {
        self.id = id
        self.reportedUserId = reportedUserId
        self.reason = reason
        self.createdAt = createdAt
    }
}
