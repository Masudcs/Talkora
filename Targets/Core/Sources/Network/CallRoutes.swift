import Foundation

/// Call history and lifecycle. `start` creates a call that begins as "ringing"; `end` records the final outcome and duration in seconds.
public enum CallRoutes: EndpointConvertible {
    case history
    case start(conversationId: String, counterpartId: String, type: String, direction: String)
    case end(callId: String, outcome: String, duration: TimeInterval)

    public var endpoint: Endpoint {
        switch self {
        case .history:
            return Endpoint(path: "/calls")
        case .start(let conversationId, let counterpartId, let type, let direction):
            return Endpoint(path: "/calls", method: .post,
                            body: StartBody(conversationId: conversationId, counterpartId: counterpartId, type: type, direction: direction))
        case .end(let callId, let outcome, let duration):
            return Endpoint(path: "/calls/\(callId)", method: .patch, body: EndBody(outcome: outcome, duration: duration))
        }
    }
}

// MARK: - Request bodies

/// Encodable request bodies; `type`, `direction` and `outcome` carry the raw values of `CallType`, `CallDirection` and `CallOutcome`.
public extension CallRoutes {
    struct StartBody: Encodable, Sendable { let conversationId: String; let counterpartId: String; let type: String; let direction: String }
    struct EndBody: Encodable, Sendable { let outcome: String; let duration: TimeInterval }
}
