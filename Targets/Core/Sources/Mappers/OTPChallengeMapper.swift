import Foundation

/// `debugHint` is not on the wire; the repository supplies it (non-production only).
public extension OTPChallengeDTO {
    func toDomain(debugHint: String?) -> OTPChallenge {
        OTPChallenge(
            id: id,
            phoneNumber: phoneNumber,
            expiresAt: ISO8601.date(from: expiresAt),
            debugHint: debugHint
        )
    }
}
