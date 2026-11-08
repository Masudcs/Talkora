import Foundation

/// Raised by `ContactRepository` when the backend rejects a contact request for sending too many too fast.
public enum ContactError: AppError {
    case throttled

    public var userMessage: String {
        switch self {
        case .throttled:
            return "You're sending requests too quickly. Please wait a bit and try again."
        }
    }

    public var isRetryable: Bool { true }
}
