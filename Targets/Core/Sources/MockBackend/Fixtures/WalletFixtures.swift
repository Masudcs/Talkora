import Foundation

/// Seeded per user, keyed by user id. `u1` ("You") starts unverified so the KYC step
/// in the Payments module is actually demoable on first use, not pre-skipped.
public enum WalletFixtures {
    public static let seed: [String: WalletDTO] = [
        "u1": WalletDTO(balance: 250, kycStatus: "notStarted"),
        "u2": WalletDTO(balance: 480, kycStatus: "verified", kycFullName: "Amara Chen", kycCountry: "US"),
        "u3": WalletDTO(balance: 120, kycStatus: "verified", kycFullName: "Diego Fernández", kycCountry: "MX"),
        "u4": WalletDTO(balance: 60, kycStatus: "verified", kycFullName: "Priya Nair", kycCountry: "IN"),
        "u5": WalletDTO(balance: 300, kycStatus: "verified", kycFullName: "Kwame Boateng", kycCountry: "GH"),
        "u6": WalletDTO(balance: 90, kycStatus: "notStarted"),
        "u7": WalletDTO(balance: 500, kycStatus: "verified", kycFullName: "Sofia Rossi", kycCountry: "IT"),
        "u8": WalletDTO(balance: 40, kycStatus: "notStarted"),
    ]
}
