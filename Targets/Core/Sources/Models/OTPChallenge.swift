import Foundation

/// A pending phone verification, valid until `expiresAt`.
public struct OTPChallenge: Identifiable, Hashable, Sendable {
    public let id: String
    public let phoneNumber: String
    public let expiresAt: Date
    /// Non-nil only outside Production — shows the fixed demo code in the UI so anyone
    /// trying the app isn't stuck waiting for a real SMS that will never arrive.
    public let debugHint: String?

    public init(id: String, phoneNumber: String, expiresAt: Date, debugHint: String?) {
        self.id = id
        self.phoneNumber = phoneNumber
        self.expiresAt = expiresAt
        self.debugHint = debugHint
    }
}
