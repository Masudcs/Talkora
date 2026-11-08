import Foundation

/// Transport-level failures normalized for the UI through `AppError`. `RealAPIClient` maps HTTP status codes onto these (401/403 to `unauthorized`, 404, 429, 5xx); `MockAPIClient` throws them directly.
public enum APIError: AppError, Sendable {
    case network(underlying: String)
    case decoding(underlying: String)
    case unauthorized
    case notFound
    case rateLimited
    case serverError(statusCode: Int)
    case custom(message: String, retryable: Bool)

    public var userMessage: String {
        switch self {
        case .network:
            return "You appear to be offline. Check your connection and try again."
        case .decoding:
            return "Something went wrong loading that content."
        case .unauthorized:
            return "Your session has expired. Please sign in again."
        case .notFound:
            return "That couldn't be found."
        case .rateLimited:
            return "You're doing that too much. Please wait a moment."
        case .serverError:
            return "Our servers had a problem. Please try again shortly."
        case .custom(let message, _):
            return message
        }
    }

    public var isRetryable: Bool {
        switch self {
        case .network, .rateLimited, .serverError: return true
        case .unauthorized, .notFound, .decoding: return false
        case .custom(_, let retryable): return retryable
        }
    }
}
