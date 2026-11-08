import Foundation

/// Shared ISO 8601 (`withInternetDateTime`) formatting for DTO date strings. `date(from:)` falls back to the current date on bad input rather than failing.
public enum ISO8601 {
    public static let formatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()

    public static func date(from string: String) -> Date {
        formatter.date(from: string) ?? Date()
    }

    public static func string(from date: Date) -> String {
        formatter.string(from: date)
    }
}
