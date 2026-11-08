import Foundation

/// Generates a bot's reply text server-side, based on its capability — proves the
/// "automation" pattern with real (if simple) logic, not just another canned pool.
public enum BotResponder {
    private static let facts = [
        "Octopuses have three hearts.",
        "Honey never spoils.",
        "Bananas are berries, but strawberries aren't.",
        "A day on Venus is longer than its year.",
        "Sharks existed before trees.",
    ]

    public static func reply(capability: String, toUserText userText: String) -> String {
        switch capability {
        case "reminders":
            let trimmed = userText.trimmingCharacters(in: .whitespacesAndNewlines)
            let subject = trimmed.isEmpty ? "that" : trimmed
            return "⏰ Got it — I'll remind you: \"\(subject)\""
        case "funFacts":
            return "🧠 Did you know: \(facts.randomElement() ?? facts[0])"
        default:
            return CannedReplies.random()
        }
    }
}
