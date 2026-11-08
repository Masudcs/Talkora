import Foundation

/// The full payments surface. ViewModels depend on the narrowest protocol they need
/// (`IWalletRepository` or `IPaymentTransferRepository`), like MyStore's `IReplenishmentOrderRepository`.
public protocol IPaymentRepository: IWalletRepository, IPaymentTransferRepository {}

public protocol IWalletRepository: Sendable {
    func wallet() async throws -> Wallet
    func submitKYC(fullName: String, country: String) async throws -> KYCStatus
    /// Demo-only convenience: real apps top up from a linked bank/card, which has no
    /// meaning in a backend-less mock — this just credits the wallet directly.
    func topUp(amount: Double) async throws -> Wallet
}

public protocol IPaymentTransferRepository: Sendable {
    func transactions() async throws -> [PaymentTransaction]
    func sendMoney(to userId: String, amount: Double, note: String?, conversationId: String?) async throws -> PaymentTransaction
    func requestMoney(from userId: String, amount: Double, note: String?, conversationId: String?) async throws -> PaymentTransaction
    func respondToRequest(_ transactionId: String, accept: Bool) async throws -> PaymentTransaction
}
