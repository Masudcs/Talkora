import Foundation

public enum CallType: String, Sendable {
    case voice
    case video
}

public enum CallDirection: String, Sendable {
    case incoming
    case outgoing
}

/// The final result of a call. The in-progress "ringing" state exists only on the wire (`CallDTO`), not here.
public enum CallOutcome: String, Sendable {
    case completed
    case noAnswer
    case declined
    case missed
    case failed
}

/// A call log entry; `duration` is in seconds and is 0 for calls that were never answered.
public struct Call: Identifiable, Hashable, Sendable {
    public let id: String
    public let conversationId: String
    public let counterpartId: String
    public let type: CallType
    public let direction: CallDirection
    public let outcome: CallOutcome
    public let startedAt: Date
    public let duration: TimeInterval

    public init(id: String, conversationId: String, counterpartId: String, type: CallType, direction: CallDirection, outcome: CallOutcome, startedAt: Date, duration: TimeInterval) {
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
