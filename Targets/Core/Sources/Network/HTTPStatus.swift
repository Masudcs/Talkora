import Foundation

/// Standard HTTP reason phrases for status codes (e.g. 404 -> "not found"), capitalised for display.
/// `-1` means no response was received at all (offline, timeout, DNS failure).
public enum HTTPStatus {
    public static func message(for code: Int) -> String {
        guard code > 0 else { return "No internet connection. Please try again." }
        let phrase = HTTPURLResponse.localizedString(forStatusCode: code)
        return phrase.prefix(1).uppercased() + phrase.dropFirst()
    }
}
