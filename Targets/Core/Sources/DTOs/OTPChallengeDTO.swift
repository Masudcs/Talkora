import Foundation

/// Wire-format representation of an OTP challenge. Deliberately does not carry the actual
/// code — a real server would never return it either; verification happens server-side.
public struct OTPChallengeDTO: Codable, Sendable, Hashable {
    public let id: String
    public let phoneNumber: String
    public let expiresAt: String

    public init(id: String, phoneNumber: String, expiresAt: String) {
        self.id = id
        self.phoneNumber = phoneNumber
        self.expiresAt = expiresAt
    }
}
