import Foundation

/// Error protocol every domain/repository error should conform to, so every ViewModel
/// and shared `ErrorStateView` can render a consistent, user-facing message + retry affordance.
public protocol AppError: Error {
    var userMessage: String { get }
    var isRetryable: Bool { get }
}

/// Fallback wrapper for errors that don't already conform to `AppError` (e.g. `Codable`
/// decoding failures surfaced from the mock API layer).
public struct GenericAppError: AppError {
    public let underlying: Error
    public let userMessage: String
    public let isRetryable: Bool

    public init(underlying: Error, userMessage: String = "Something went wrong. Please try again.", isRetryable: Bool = true) {
        self.underlying = underlying
        self.userMessage = userMessage
        self.isRetryable = isRetryable
    }
}

public extension Error {
    /// Normalizes any thrown error into an `AppError` so ViewModels can expose it to the
    /// shared error views without repeating the cast-or-wrap at every call site.
    var asAppError: AppError {
        (self as? AppError) ?? GenericAppError(underlying: self)
    }
}
