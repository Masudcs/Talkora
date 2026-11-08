import Alamofire
import Foundation
import Moya

/// The heart of every API call: a `MoyaProvider` that returns `NetworkResult` instead of throwing.
///
/// `API` is a feature's endpoint enum (e.g. `APIProvider<AuthTarget>`). Cancellation, stubbing
/// (for tests/previews), error-message generation and the `onError` hook live here so no
/// Repository or ViewModel repeats them.
public final class APIProvider<API: APITarget>: MoyaProvider<API> {
    private let onError: (_ route: String, _ code: Int) -> Void
    private let isProduction: Bool
    private let decoder: JSONDecoder
    private let logger = AppLogger(category: .network)

    /// - Parameters:
    ///   - isStubbed: Return the target's stub data instead of hitting the network.
    ///   - stubBehavior: Delay applied to stubbed responses.
    ///   - isProduction: Without a server message, production shows only the standard status text.
    ///   - onError: Called with the route and status code whenever a call fails.
    public init(
        isStubbed: Bool = false,
        stubBehavior: StubBehavior = .delayed(seconds: 1),
        session: Session = .default,
        isProduction: Bool = AppEnvironment.current.name == .production,
        onError: @escaping (_ route: String, _ code: Int) -> Void = { _, _ in }
    ) {
        var plugins: [PluginType] = [CachePolicyPlugin()]
        #if DEBUG
        plugins.append(NetworkLoggerPlugin(configuration: .init(logOptions: .default)))
        #endif

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        self.onError = onError
        self.isProduction = isProduction
        self.decoder = decoder

        let shouldStub = isStubbed || isStubNetworkEnabled

        super.init(
            endpointClosure: { target in
                Moya.Endpoint(
                    url: target.baseURL.appendingPathComponent(target.path).absoluteString,
                    sampleResponseClosure: {
                        .networkResponse((target as? APITarget)?.stubStatusCode ?? 200, target.sampleData)
                    },
                    method: target.method,
                    task: target.task,
                    httpHeaderFields: target.headers
                )
            },
            stubClosure: { _ in shouldStub ? stubBehavior : .never },
            callbackQueue: DispatchQueue(label: API.queueLabel),
            session: session,
            plugins: plugins
        )
    }
}

// MARK: - Requests

public extension APIProvider {
    /// The result returned for a cancelled request. Callers treat status `-1` with `RequestCancelled` as a cancellation, not a failure (`RealAPIClient` rethrows it as `CancellationError`).
    static func canceledRequestResult<T: Decodable>() -> NetworkResult<T> {
        .failure(
            error: MoyaError.underlying(RequestCancelled(), nil),
            message: "Request cancelled!",
            statusCode: -1
        )
    }

    /// Request for an API call to the `endpoint` for a `T` response.
    func request<T: Decodable & Sendable>(on endpoint: API) async -> NetworkResult<T> {
        await request(T.self, on: endpoint)
    }

    /// Request for an API call to the `endpoint` for a `resourceType` response.
    func request<T: Decodable & Sendable>(_ resourceType: T.Type, on endpoint: API) async -> NetworkResult<T> {
        if _Concurrency.Task.isCancelled { return Self.canceledRequestResult() }

        let handle = CancellableHandle()
        let result: Result<Response, MoyaError> = await withTaskCancellationHandler {
            await withCheckedContinuation { (continuation: CheckedContinuation<Result<Response, MoyaError>, Never>) in
                handle.set(request(endpoint) { continuation.resume(returning: $0) })
            }
        } onCancel: {
            handle.cancel()
        }

        if _Concurrency.Task.isCancelled { return Self.canceledRequestResult() }

        switch result {
        case .success(let response):
            return process(response, as: resourceType, endpoint: endpoint)
        case .failure(let error):
            return failure(for: error, endpoint: endpoint)
        }
    }
}

// MARK: - Response handling

private extension APIProvider {
    func process<T: Decodable & Sendable>(_ response: Response, as resourceType: T.Type, endpoint: API) -> NetworkResult<T> {
        guard (200...299).contains(response.statusCode) else {
            return failure(for: .statusCode(response), endpoint: endpoint)
        }

        if resourceType is EmptyResponse.Type, let empty = EmptyResponse() as? T {
            return .success( empty)
        }

        do {
            return .success( try response.map(T.self, using: decoder))
        } catch let error as MoyaError {
            return failure(for: error, endpoint: endpoint)
        } catch {
            return failure(for: .underlying(error, response), endpoint: endpoint)
        }
    }

    func failure<T: Decodable>(for error: MoyaError, endpoint: API) -> NetworkResult<T> {
        if case .underlying(let underlying, _) = error, underlying is RequestCancelled || (underlying as? URLError)?.code == .cancelled
            || ((underlying as? AFError)?.isExplicitlyCancelledError ?? false) {
            return Self.canceledRequestResult()
        }

        let statusCode = error.response?.statusCode ?? -1
        logger.error("\(endpoint.path) failed (\(statusCode)): \(error)")
        onError(endpoint.path, statusCode)

        return .failure(error: error, message: errorMessage(for: error, statusCode: statusCode), statusCode: statusCode)
    }

    func errorMessage(for error: MoyaError, statusCode: Int) -> String {
        // A 2xx response that could not be decoded.
        if (200...299).contains(statusCode), case .objectMapping = error {
            return "Invalid server response. Please try again."
        }

        // A message from the server is always the best text to show.
        if let parsed = parseResponseErrorMessage(from: error) { return parsed }

        if isProduction {
            // Without a server message, production shows only the standard status text.
            guard case .statusCode(let response) = error else {
                return statusCode == -1 ? HTTPStatus.message(for: -1) : "Something went wrong. Please try again."
            }
            return "(\(response.statusCode)) \(HTTPStatus.message(for: response.statusCode))"
        }

        let message = readableMessage(for: error)
        return statusCode > 0 ? "(\(statusCode)) \(message)" : message
    }

    /// The `message` field of the server's error body, if there is one.
    func parseResponseErrorMessage(from error: MoyaError) -> String? {
        guard let data = error.response?.data,
              let body = try? decoder.decode(ServerErrorBody.self, from: data),
              body.message?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false else { return nil }
        return body.displayMessage()
    }

    func readableMessage(for error: MoyaError) -> String {
        switch error {
        case .statusCode(let response):
            return HTTPStatus.message(for: response.statusCode)
        case .underlying(let underlying, _):
            if let afError = underlying as? AFError, case .sessionTaskFailed(let sessionError) = afError {
                return sessionError.localizedDescription
            }
            return underlying.localizedDescription
        default:
            return error.localizedDescription
        }
    }
}

/// Lets the task-cancellation handler cancel the in-flight Moya request, even if
/// cancellation arrives before the request has started.
private final class CancellableHandle: @unchecked Sendable {
    private let lock = NSLock()
    private var cancellable: Moya.Cancellable?
    private var isCancelled = false

    func set(_ cancellable: Moya.Cancellable) {
        lock.lock(); defer { lock.unlock() }
        self.cancellable = cancellable
        if isCancelled { cancellable.cancel() }
    }

    func cancel() {
        lock.lock(); defer { lock.unlock() }
        isCancelled = true
        cancellable?.cancel()
    }
}
