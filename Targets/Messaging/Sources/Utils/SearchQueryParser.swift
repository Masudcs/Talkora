import Foundation
import Core

/// Parses typed filter syntax out of a free-text search query — `from:@handle`,
/// `has:media`, `after:2024-01-01`, `before:2024-01-01` — leaving the remaining words as
/// the plain-text search term. Handle resolution (`from:@amara` -> a user id) happens
/// in the ViewModel, since the parser has no repository access.
enum SearchQueryParser {
    struct ParsedQuery {
        var text: String
        var fromHandle: String?
        var hasMediaOnly: Bool
        var after: Date?
        var before: Date?
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = TimeZone(identifier: "UTC")
        return formatter
    }()

    /// Splits on spaces and matches prefixes case-insensitively. Unparseable dates (`after:garbage`) become nil rather than staying in the text,
    /// and a repeated filter keeps the last value.
    static func parse(_ raw: String) -> ParsedQuery {
        var fromHandle: String?
        var hasMediaOnly = false
        var after: Date?
        var before: Date?
        var remainingWords: [String] = []

        for token in raw.split(separator: " ") {
            let word = String(token)
            if word.lowercased().hasPrefix("from:") {
                fromHandle = String(word.dropFirst(5)).trimmingCharacters(in: CharacterSet(charactersIn: "@"))
            } else if word.lowercased() == "has:media" {
                hasMediaOnly = true
            } else if word.lowercased().hasPrefix("after:") {
                after = dateFormatter.date(from: String(word.dropFirst(6)))
            } else if word.lowercased().hasPrefix("before:") {
                before = dateFormatter.date(from: String(word.dropFirst(7)))
            } else {
                remainingWords.append(word)
            }
        }

        return ParsedQuery(
            text: remainingWords.joined(separator: " "),
            fromHandle: fromHandle,
            hasMediaOnly: hasMediaOnly,
            after: after,
            before: before
        )
    }
}
