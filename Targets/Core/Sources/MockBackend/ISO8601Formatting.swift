import Foundation

/// Same formatter as `ISO8601`, but `date(from:)` returns `nil` on bad input instead of falling back to the current date.
public enum ISO8601Formatting {
    public static let formatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()

    public static func string(from date: Date) -> String {
        formatter.string(from: date)
    }

    public static func date(from string: String) -> Date? {
        formatter.date(from: string)
    }
}
