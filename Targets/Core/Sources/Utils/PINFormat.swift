import Foundation

/// Shared rules for the 4-digit app-lock PIN, used by onboarding and the privacy hub.
public enum PINFormat {
    public static let length = 4

    /// Keeps digits only and caps the length, so every PIN field behaves identically.
    public static func sanitize(_ input: String) -> String {
        String(input.filter(\.isNumber).prefix(length))
    }
}
