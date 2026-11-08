import Alamofire
import Foundation
import Moya

/// `APIClientProtocol` backed by `APIProvider` (the Moya-based networking core).
/// Used for the `stubbed` backend (debug builds, answering from `StubCatalog`) and the `live`
/// backend (real network calls, which still need sign-in and token storage); see `APIBackend`.
///
/// Parameter convention (matches how `MockAPIClient` reads them): `endpoint.query` is sent as
/// URL query items for GET/DELETE and as a JSON body for POST/PUT/PATCH.
public final class RealAPIClient: APIClientProtocol, @unchecked Sendable {
    private let baseURL: URL
    private let tokenProvider: @Sendable () -> String?
    private let backend: APIProvider<EndpointTarget>
    #if DEBUG
    private let stubCatalog: StubCatalog
    private let stubFailures: StubFailureRules
    #endif

    public init(
        baseURL: URL,
        session: Session = .default,
        tokenProvider: @escaping @Sendable () -> String? = { nil },
        onError: @escaping (_ route: String, _ code: Int) -> Void = { _, _ in }
    ) {
        self.baseURL = baseURL
        self.tokenProvider = tokenProvider
        self.backend = APIProvider<EndpointTarget>(session: session, onError: onError)
        #if DEBUG
        self.stubCatalog = .shared
        self.stubFailures = .none
        #endif
    }

    #if DEBUG
    /// Debug builds only: answers from the bundled `StubCatalog` (see `APIBackend.stubbed`).
    public init(
        baseURL: URL,
        session: Session = .default,
        tokenProvider: @escaping @Sendable () -> String? = { nil },
        isStubbed: Bool,
        stubBehavior: StubBehavior = .delayed(seconds: 0.2),
        stubCatalog: StubCatalog = .shared,
        stubFailures: StubFailureRules = .fromLaunch,
        onError: @escaping (_ route: String, _ code: Int) -> Void = { _, _ in }
    ) {
        self.baseURL = baseURL
        self.tokenProvider = tokenProvider
        self.stubCatalog = stubCatalog
        self.stubFailures = stubFailures
        self.backend = APIProvider<EndpointTarget>(isStubbed: isStubbed, stubBehavior: stubBehavior, session: session, onError: onError)
    }
    #endif

    public func request<T: Decodable & Sendable>(_ endpoint: Endpoint) async throws -> T {
        try unwrap(await backend.request(T.self, on: try target(for: endpoint)))
    }

    public func requestPage<T: Decodable & Sendable>(_ endpoint: Endpoint, cursor: String?, pageSize: Int) async throws -> Page<T> {
        var query: [String: String] = [:]
        if let cursor { query["cursor"] = cursor }
        query["pageSize"] = String(pageSize)
        let paged = endpoint.addingQuery(query)
        let body: PageBody<T> = try unwrap(await backend.request(PageBody<T>.self, on: try target(for: paged)))
        return Page(items: body.items, nextCursor: body.nextCursor, hasMore: body.hasMore)
    }

    public func requestVoid(_ endpoint: Endpoint) async throws {
        let _: EmptyResponse = try unwrap(await backend.request(EmptyResponse.self, on: try target(for: endpoint)))
    }

    // MARK: - Private

    private struct PageBody<T: Decodable & Sendable>: Decodable, Sendable {
        let items: [T]
        let nextCursor: String?
        let hasMore: Bool
    }

    private func target(for endpoint: Endpoint) throws -> EndpointTarget {
        var headers: [String: String] = [:]
        if endpoint.requiresAuth {
            guard let token = tokenProvider() else { throw APIError.unauthorized }
            headers["Authorization"] = "Bearer \(token)"
        }
        if endpoint.body != nil { headers["Content-Type"] = "application/json" }
        #if DEBUG
        return EndpointTarget(baseURL: baseURL, endpoint: endpoint, headers: headers, stubCatalog: stubCatalog, stubFailures: stubFailures)
        #else
        return EndpointTarget(baseURL: baseURL, endpoint: endpoint, headers: headers)
        #endif
    }

    private func unwrap<T>(_ result: NetworkResult<T>) throws -> T {
        switch result {
        case .success(let response):
            return response
        case .failure(let error, let message, let statusCode):
            if case .underlying(let underlying, _) = error, underlying is RequestCancelled { throw CancellationError() }
            if case .objectMapping = error { throw APIError.decoding(underlying: message) }
            switch statusCode {
            case -1: throw APIError.network(underlying: message)
            case 401, 403: throw APIError.unauthorized
            case 404: throw APIError.notFound
            case 429: throw APIError.rateLimited
            case 500...: throw APIError.serverError(statusCode: statusCode)
            default: throw APIError.custom(message: message, retryable: false)
            }
        }
    }
}

/// Adapts the existing `Endpoint` value to `APITarget` so `APIProvider` can send it.
public struct EndpointTarget: APITarget {
    public let baseURL: URL
    public let endpoint: Endpoint
    public let headers: [String: String]?
    #if DEBUG
    public let stubCatalog: StubCatalog
    public let stubFailures: StubFailureRules

    public init(baseURL: URL, endpoint: Endpoint, headers: [String: String]?, stubCatalog: StubCatalog = .shared, stubFailures: StubFailureRules = .none) {
        self.baseURL = baseURL
        self.endpoint = endpoint
        self.headers = headers
        self.stubCatalog = stubCatalog
        self.stubFailures = stubFailures
    }
    #else
    public init(baseURL: URL, endpoint: Endpoint, headers: [String: String]?) {
        self.baseURL = baseURL
        self.endpoint = endpoint
        self.headers = headers
    }
    #endif

    public var path: String { endpoint.path }
    public var method: Moya.Method { Moya.Method(rawValue: endpoint.method.rawValue.uppercased()) }

    public var task: Moya.Task {
        if let body = endpoint.body { return .requestData(body.json) }
        guard !endpoint.query.isEmpty else { return .requestPlain }
        switch endpoint.method {
        case .get, .delete:
            return .requestParameters(parameters: endpoint.query, encoding: URLEncoding.queryString)
        default:
            return .requestParameters(parameters: endpoint.query, encoding: JSONEncoding.default)
        }
    }

    #if DEBUG
    // MARK: Stubbed responses (debug builds only; used when the provider is stubbed)

    public var stubResponseType: StubResponseKind { .success }

    public var stubStatusCode: Int {
        stubFailures.status(for: endpoint) ?? stubCatalog.entry(for: endpoint)?.status ?? 404
    }

    public var stubData: Data? {
        if let failure = stubFailures.status(for: endpoint) { return StubFailureRules.errorBody(for: failure) }
        if let entry = stubCatalog.entry(for: endpoint) { return entry.body }
        let message = "No stub recorded for \(StubCatalog.key(method: endpoint.method, path: endpoint.path))"
        return try? JSONEncoder().encode(ServerErrorBody(success: false, message: message))
    }
    #endif
}
