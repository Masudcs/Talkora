import Foundation
import Core

/// Validates the "username or email" sign-in field. Anything containing `@` must be a
/// well-formed email address; everything else must be a valid username.
enum LoginIdentifierValidator {
    /// What the input turned out to be, carrying the normalised value.
    enum Kind: Equatable {
        case email(String)
        case username(String)

        var value: String {
            switch self {
            case .email(let value), .username(let value): value
            }
        }
    }

    enum ValidationError: Error, Equatable {
        case empty
        case invalidEmail
        case usernameLength
        case usernameCharacters
    }

    /// Username length limit, in characters.
    static let usernameLengthRange = 3...30
    /// Practical maximum length of an email address.
    static let maxEmailLength = 254

    /// Trims the input and classifies it. Returns the normalised value (lowercased email, or trimmed username) on success.
    static func validate(_ input: String) -> Result<Kind, ValidationError> {
        let value = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty else { return .failure(.empty) }
        return value.contains("@") ? validateEmail(value) : validateUsername(value)
    }

    /// Emails are case-insensitive in practice, so they are normalised to lowercase.
    private static func validateEmail(_ value: String) -> Result<Kind, ValidationError> {
        let email = value.lowercased()
        let pattern = #"^[a-z0-9._%+\-]+@[a-z0-9\-]+(\.[a-z0-9\-]+)*\.[a-z]{2,}$"#
        guard email.count <= maxEmailLength,
              !email.contains(".."),
              !email.hasPrefix("."),
              email.range(of: pattern, options: .regularExpression) != nil,
              let local = email.split(separator: "@").first, !local.hasSuffix(".") else {
            return .failure(.invalidEmail)
        }
        return .success(.email(email))
    }

    /// Letters, digits, `_` and `.`; no leading or trailing dot.
    private static func validateUsername(_ value: String) -> Result<Kind, ValidationError> {
        guard usernameLengthRange.contains(value.count) else { return .failure(.usernameLength) }
        let pattern = #"^[A-Za-z0-9_]+(\.[A-Za-z0-9_]+)*$"#
        guard value.range(of: pattern, options: .regularExpression) != nil else {
            return .failure(.usernameCharacters)
        }
        return .success(.username(value))
    }

    /// User-facing text for each validation failure.
    static func message(for error: ValidationError) -> String {
        switch error {
        case .empty: "Enter your username or email."
        case .invalidEmail: "Enter a valid email address, like name@example.com."
        case .usernameLength: "A username has 3 to 30 characters."
        case .usernameCharacters: "Usernames can use letters, numbers, underscores and dots only."
        }
    }
}
