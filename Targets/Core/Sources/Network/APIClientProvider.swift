import Foundation

/// The API client every repository uses by default, so a repository can be created with no arguments
/// (`ChatRepository()`), like MyStore's `XRepository()`. The client is chosen on first use from `APIBackend.current`
/// (the `-talkora-backend` launch argument or `TALKORA_BACKEND`): the in-memory mock by default, the stubbed
/// Moya stack, or the live one. Tests and previews can set `client`, or pass one: `ChatRepository(api: ...)`.
public final class APIClientProvider: @unchecked Sendable {
    public static let shared = APIClientProvider()

    private let lock = NSLock()
    private var _client: APIClientProtocol?

    public init() {}

    public var client: APIClientProtocol {
        get {
            lock.lock()
            defer { lock.unlock() }
            if let _client { return _client }
            let client = Self.makeAPIClient(for: .current, environment: .current)
            _client = client
            return client
        }
        set {
            lock.lock()
            defer { lock.unlock() }
            _client = newValue
        }
    }

    /// The client for a backend, without touching the shared provider (tests use this).
    public static func makeAPIClient(for backend: APIBackend, environment: AppEnvironment) -> APIClientProtocol {
        switch backend {
        case .mock:
            return MockAPIClient(store: .shared, environment: environment)
        case .stubbed:
            #if DEBUG
            // No real session exists in stubbed mode, so hand out a placeholder token for `requiresAuth` calls.
            return RealAPIClient(
                baseURL: environment.apiBaseURL,
                tokenProvider: { "stub-token" },
                isStubbed: true
            )
            #else
            // Stub code isn't compiled into release builds; `APIBackend.current` never selects this there.
            return MockAPIClient(store: .shared, environment: environment)
            #endif
        case .live:
            return RealAPIClient(baseURL: environment.apiBaseURL)
        }
    }
}
