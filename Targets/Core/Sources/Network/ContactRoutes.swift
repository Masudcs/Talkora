import Foundation

/// Device contacts, user search, contact requests, connections and discoverability. `simulateIncomingRequest` is a demo-only hook.
public enum ContactRoutes: EndpointConvertible {
    case deviceContacts
    case searchUsers(query: String)
    case sendRequest(toUserId: String)
    case incomingRequests
    case respond(requestId: String, accept: Bool)
    case connections
    case discoverability
    case setDiscoverability(value: String)
    case connectViaQR(userId: String)
    case simulateIncomingRequest

    public var endpoint: Endpoint {
        switch self {
        case .deviceContacts:
            return Endpoint(path: "/device-contacts")
        case .searchUsers(let query):
            return Endpoint(path: "/user-search", query: ["query": query])
        case .sendRequest(let toUserId):
            return Endpoint(path: "/contact-requests", method: .post, body: ToUserBody(toUserId: toUserId))
        case .incomingRequests:
            return Endpoint(path: "/contact-requests")
        case .respond(let requestId, let accept):
            return Endpoint(path: "/contact-requests/\(requestId)", method: .patch, body: AcceptBody(accept: accept))
        case .connections:
            return Endpoint(path: "/connections")
        case .discoverability:
            return Endpoint(path: "/discoverability")
        case .setDiscoverability(let value):
            return Endpoint(path: "/discoverability", method: .put, body: ValueBody(value: value))
        case .connectViaQR(let userId):
            return Endpoint(path: "/contacts/qr-connect", method: .post, body: UserIdBody(userId: userId))
        case .simulateIncomingRequest:
            return Endpoint(path: "/contact-requests/simulate", method: .post)
        }
    }
}

// MARK: - Request bodies

/// Encodable request bodies for these routes.
public extension ContactRoutes {
    struct ToUserBody: Encodable, Sendable { let toUserId: String }
    struct AcceptBody: Encodable, Sendable { let accept: Bool }
    struct ValueBody: Encodable, Sendable { let value: String }
    struct UserIdBody: Encodable, Sendable { let userId: String }
}
