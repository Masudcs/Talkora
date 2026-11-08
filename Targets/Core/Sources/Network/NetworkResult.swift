import Foundation
import Moya

/// Outcome of a `APIProvider` call: the decoded response, or the error plus a user-presentable
/// message and the HTTP status code (`-1` when no response was received).
public enum NetworkResult<T: Decodable & Sendable>: Sendable {
    case success(T)
    case failure(error: MoyaError, message: String, statusCode: Int)
}

/// Marks a request that was cancelled along with its task.
public struct RequestCancelled: Error {}

/// Response model for calls where the body is irrelevant (2xx with empty/ignored body).
public struct EmptyResponse: Decodable, Sendable {
    public init() {}
    public init(from decoder: Decoder) throws {}
}

/// Error body the server returns on failure: `{"success": false, "message": "..."}`.
public struct ServerErrorBody: Codable, Sendable {
    public let success: Bool?
    public let message: String?

    public init(success: Bool?, message: String?) {
        self.success = success
        self.message = message
    }

    /// The server's message, or `fallback` when it is missing or blank.
    public func displayMessage(orDefault fallback: String = "Something went wrong. Try again.") -> String {
        let trimmed = message?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmed.isEmpty ? fallback : trimmed
    }
}
