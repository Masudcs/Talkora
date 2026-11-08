import Foundation

/// Unknown `type`, `direction` or `outcome` values fall back to `.voice`, `.outgoing` and `.failed`. `CallOutcome` has no "ringing" case, so a call still ringing on the wire maps to `.failed`.
public extension CallDTO {
    func toDomain() -> Call {
        Call(
            id: id,
            conversationId: conversationId,
            counterpartId: counterpartId,
            type: CallType(rawValue: type) ?? .voice,
            direction: CallDirection(rawValue: direction) ?? .outgoing,
            outcome: CallOutcome(rawValue: outcome) ?? .failed,
            startedAt: ISO8601.date(from: startedAt),
            duration: duration
        )
    }
}
