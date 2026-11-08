import Foundation

/// Wire-format bot directory entry. `id` equals the bot's `UserDTO` id; `capability` is a `BotCapability` raw value ("reminders" | "funFacts").
public struct BotDTO: Codable, Sendable, Hashable {
    public let id: String
    public let name: String
    public let description: String
    public let capability: String

    public init(id: String, name: String, description: String, capability: String) {
        self.id = id
        self.name = name
        self.description = description
        self.capability = capability
    }
}
