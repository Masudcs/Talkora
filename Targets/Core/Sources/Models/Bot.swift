import Foundation

/// Uncommon (Discord-like directory) rather than hidden behind an invite/add-by-id
/// flow — every bot is listed and startable from the Messaging module's bot directory.
public enum BotCapability: String, Sendable {
    /// Proves the pattern with a real capability: schedules an actual local
    /// notification (via `NotificationScheduler`), not just a canned text reply.
    case reminders
    case funFacts
}

public struct Bot: Identifiable, Hashable, Sendable {
    /// Same id as the underlying bot `User` — a bot chat is a normal direct
    /// conversation with a participant that happens to be a bot.
    public let id: String
    public let name: String
    public let description: String
    public let capability: BotCapability

    public init(id: String, name: String, description: String, capability: BotCapability) {
        self.id = id
        self.name = name
        self.description = description
        self.capability = capability
    }
}
