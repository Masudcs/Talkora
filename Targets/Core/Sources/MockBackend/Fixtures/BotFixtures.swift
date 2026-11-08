import Foundation

/// `id` matches the corresponding bot `UserDTO` in `UserFixtures` — a bot chat is just
/// a direct conversation whose other participant happens to be a bot.
public enum BotFixtures {
    public static let seed: [BotDTO] = [
        BotDTO(id: "bot1", name: "Reminder Bot", description: "Tell it what to remember and it'll schedule a real reminder notification.", capability: "reminders"),
        BotDTO(id: "bot2", name: "Fact Bot", description: "Send it anything and get a random fun fact back.", capability: "funFacts"),
    ]
}
