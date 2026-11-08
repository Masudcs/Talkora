import Foundation

/// Everything an API client needs to describe a single request.
/// Modeled exactly like a REST endpoint so `MockAPIClient` and `RealAPIClient` share the same
/// call sites in every Repository.
public struct Endpoint: Sendable, Hashable {
    /// HTTP verb; the raw value is uppercased to build the Moya method.
    public enum Method: String, Sendable {
        case get, post, put, patch, delete
    }

    /// Request path relative to the API base URL, e.g. `/conversations/c1/messages`.
    public let path: String
    public let method: Method
    /// Flat string parameters. For GET/DELETE they become URL query items. When a typed `body` is
    /// given, this holds its flattened form instead, which is what `MockAPIClient` reads.
    public let query: [String: String]
    /// Typed JSON body for POST/PUT/PATCH. `RealAPIClient` sends it as JSON.
    public let body: EndpointBody?
    /// Free-text note about the body for the untyped initializer; not sent anywhere and not used by either client.
    public let bodyDescription: String?
    /// When true, `RealAPIClient` attaches the bearer token (and throws `APIError.unauthorized` if there is none). `MockAPIClient` ignores it.
    public let requiresAuth: Bool

    public init(
        path: String,
        method: Method = .get,
        query: [String: String] = [:],
        bodyDescription: String? = nil,
        requiresAuth: Bool = true
    ) {
        self.path = path
        self.method = method
        self.query = query
        self.body = nil
        self.bodyDescription = bodyDescription
        self.requiresAuth = requiresAuth
    }

    /// An endpoint whose parameters are a typed `Encodable` body instead of loose strings.
    public init<Body: Encodable & Sendable>(
        path: String,
        method: Method,
        body: Body,
        requiresAuth: Bool = true
    ) {
        let body = EndpointBody(body)
        self.path = path
        self.method = method
        self.query = body.fields
        self.body = body
        self.bodyDescription = nil
        self.requiresAuth = requiresAuth
    }

    /// The same endpoint with extra query items (used for paging).
    public func addingQuery(_ extra: [String: String]) -> Endpoint {
        Endpoint(path: path, method: method, query: query.merging(extra) { _, new in new },
                 bodyDescription: bodyDescription, requiresAuth: requiresAuth)
    }

    /// Equality ignores the typed `body`: it is already flattened into `query`, so comparing `query` covers it.
    public static func == (lhs: Endpoint, rhs: Endpoint) -> Bool {
        lhs.path == rhs.path && lhs.method == rhs.method && lhs.query == rhs.query
            && lhs.bodyDescription == rhs.bodyDescription && lhs.requiresAuth == rhs.requiresAuth
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(path)
        hasher.combine(method)
        hasher.combine(query)
        hasher.combine(bodyDescription)
        hasher.combine(requiresAuth)
    }
}

/// A type-erased `Encodable` request body. Keeps the encoded JSON for the real network stack and a
/// flat `[String: String]` view (`true`/`false`, numbers as text, arrays comma-joined, nils omitted)
/// for the in-memory mock backend.
public struct EndpointBody: Sendable {
    public let json: Data
    public let fields: [String: String]

    public init<Body: Encodable & Sendable>(_ body: Body) {
        let data = (try? JSONEncoder().encode(body)) ?? Data("{}".utf8)
        self.json = data
        let object = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] ?? [:]
        self.fields = object.compactMapValues(Self.flatten)
    }

    private static func flatten(_ value: Any) -> String? {
        switch value {
        case let string as String:
            return string
        case let number as NSNumber:
            return CFGetTypeID(number) == CFBooleanGetTypeID() ? (number.boolValue ? "true" : "false") : number.stringValue
        case let array as [Any]:
            return array.compactMap(flatten).joined(separator: ",")
        default:
            return nil
        }
    }
}

/// One API enum per feature (e.g. `AuthRoutes`) conforms to this, so path/method/params for a
/// feature live in a single file and Repositories call `api.request(AuthRoutes.login(...))`.
public protocol EndpointConvertible {
    var endpoint: Endpoint { get }
}

public extension APIClientProtocol {
    /// Convenience overloads so repositories pass a route case (`api.request(ChatRoutes.conversations)`) instead of building the `Endpoint` themselves.
    func request<T: Decodable & Sendable>(_ target: some EndpointConvertible) async throws -> T {
        try await request(target.endpoint)
    }

    func requestVoid(_ target: some EndpointConvertible) async throws {
        try await requestVoid(target.endpoint)
    }

    func requestPage<T: Decodable & Sendable>(_ target: some EndpointConvertible, cursor: String? = nil, pageSize: Int = 30) async throws -> Page<T> {
        try await requestPage(target.endpoint, cursor: cursor, pageSize: pageSize)
    }
}
