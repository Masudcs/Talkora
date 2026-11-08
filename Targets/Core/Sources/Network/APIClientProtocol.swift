import Foundation

/// Shared contract implemented by `MockAPIClient` (an in-memory fake server, the default) and
/// `RealAPIClient` (the Moya networking stack, used for the stubbed and live backends). Every
/// Repository depends only on this protocol, so which one runs is decided in one place —
/// `APIClientProvider`, driven by `APIBackend` — and nothing else changes.
public protocol APIClientProtocol: Sendable {
    func request<T: Decodable & Sendable>(_ endpoint: Endpoint) async throws -> T
    func requestPage<T: Decodable & Sendable>(_ endpoint: Endpoint, cursor: String?, pageSize: Int) async throws -> Page<T>
    func requestVoid(_ endpoint: Endpoint) async throws
}

/// Gives `requestPage` its default first page (no cursor, 30 items).
public extension APIClientProtocol {
    func requestPage<T: Decodable & Sendable>(_ endpoint: Endpoint, cursor: String? = nil, pageSize: Int = 30) async throws -> Page<T> {
        try await requestPage(endpoint, cursor: cursor, pageSize: pageSize)
    }
}
