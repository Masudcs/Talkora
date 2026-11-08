import Foundation

/// Wire-format wallet. `kycStatus` is a `KYCStatus` raw value; the KYC name and country are kept on the wire but not exposed by the domain `Wallet`.
public struct WalletDTO: Codable, Sendable, Hashable {
    public let balance: Double
    public let kycStatus: String
    public let kycFullName: String?
    public let kycCountry: String?

    public init(balance: Double, kycStatus: String, kycFullName: String? = nil, kycCountry: String? = nil) {
        self.balance = balance
        self.kycStatus = kycStatus
        self.kycFullName = kycFullName
        self.kycCountry = kycCountry
    }
}
