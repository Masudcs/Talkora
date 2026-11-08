import Foundation

/// Unknown capability values fall back to `.funFacts`.
public extension BotDTO {
    func toDomain() -> Bot {
        Bot(id: id, name: name, description: description, capability: BotCapability(rawValue: capability) ?? .funFacts)
    }
}
