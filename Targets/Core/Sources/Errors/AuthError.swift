import Foundation

/// Sign-in failures. `AuthRepository` raises `invalidCode` and `invalidCredentials`; nothing currently throws `challengeExpired`.
public enum AuthError: AppError {
    case invalidCode
    case challengeExpired
    case invalidCredentials

    public var userMessage: String {
        switch self {
        case .invalidCode:
            return "That code doesn't look right. Please try again."
        case .challengeExpired:
            return "This code has expired. Request a new one."
        case .invalidCredentials:
            return "We couldn't find an account matching those details."
        }
    }

    public var isRetryable: Bool {
        switch self {
        case .invalidCode, .invalidCredentials: return true
        case .challengeExpired: return false
        }
    }
}
