import Foundation

/// Message search, across every conversation (`global`) or inside one. Filters travel as query items: `q`, `senderId`, `hasMedia`, and `after` / `before` as ISO 8601 strings.
public enum SearchRoutes: EndpointConvertible {
    case global(text: String, filter: MessageSearchFilter)
    case messages(conversationId: String, text: String, filter: MessageSearchFilter)

    public var endpoint: Endpoint {
        switch self {
        case .global(let text, let filter):
            return Endpoint(path: "/search", query: Self.query(text: text, filter: filter))
        case .messages(let conversationId, let text, let filter):
            return Endpoint(path: "/conversations/\(conversationId)/search", query: Self.query(text: text, filter: filter))
        }
    }

    private static func query(text: String, filter: MessageSearchFilter) -> [String: String] {
        var query = ["q": text]
        if let senderId = filter.senderId { query["senderId"] = senderId }
        if filter.hasMediaOnly { query["hasMedia"] = "true" }
        if let after = filter.after { query["after"] = ISO8601.string(from: after) }
        if let before = filter.before { query["before"] = ISO8601.string(from: before) }
        return query
    }
}
