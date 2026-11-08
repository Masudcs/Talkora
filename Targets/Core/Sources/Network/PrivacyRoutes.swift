import Foundation

/// Last-seen visibility, blocking and reporting.
public enum PrivacyRoutes: EndpointConvertible {
    case lastSeen
    case setLastSeen(value: String)
    case blockedUsers
    case blockedStatus(userId: String)
    case block(userId: String)
    case unblock(userId: String)
    case report(userId: String, reason: String)

    public var endpoint: Endpoint {
        switch self {
        case .lastSeen:
            return Endpoint(path: "/privacy/last-seen")
        case .setLastSeen(let value):
            return Endpoint(path: "/privacy/last-seen", method: .put, body: ValueBody(value: value))
        case .blockedUsers:
            return Endpoint(path: "/privacy/blocked")
        case .blockedStatus(let userId):
            return Endpoint(path: "/privacy/blocked-status", query: ["userId": userId])
        case .block(let userId):
            return Endpoint(path: "/privacy/block", method: .post, body: UserIdBody(userId: userId))
        case .unblock(let userId):
            return Endpoint(path: "/privacy/unblock", method: .post, body: UserIdBody(userId: userId))
        case .report(let userId, let reason):
            return Endpoint(path: "/privacy/report", method: .post, body: ReportBody(userId: userId, reason: reason))
        }
    }
}

// MARK: - Request bodies

/// Encodable request bodies for these routes.
public extension PrivacyRoutes {
    struct ValueBody: Encodable, Sendable { let value: String }
    struct UserIdBody: Encodable, Sendable { let userId: String }
    struct ReportBody: Encodable, Sendable { let userId: String; let reason: String }
}
