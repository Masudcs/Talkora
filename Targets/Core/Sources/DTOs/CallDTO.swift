import Foundation

/// Wire-format representation of a call log entry, as a real `/calls` response would look.
public struct CallDTO: Codable, Sendable, Hashable {
    public let id: String
    public let conversationId: String
    public let counterpartId: String
    public let type: String // "voice" | "video"
    public let direction: String // "incoming" | "outgoing"
    public let outcome: String // "ringing" (transient) | "completed" | "noAnswer" | "declined" | "missed" | "failed"
    public let startedAt: String
    public let duration: Double

    public init(
        id: String,
        conversationId: String,
        counterpartId: String,
        type: String,
        direction: String,
        outcome: String,
        startedAt: String,
        duration: Double = 0
    ) {
        self.id = id
        self.conversationId = conversationId
        self.counterpartId = counterpartId
        self.type = type
        self.direction = direction
        self.outcome = outcome
        self.startedAt = startedAt
        self.duration = duration
    }
}
