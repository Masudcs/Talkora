import Foundation

/// Unknown KYC status falls back to `.notStarted`; the KYC name and country are dropped.
public extension WalletDTO {
    func toDomain() -> Wallet {
        Wallet(balance: balance, kycStatus: KYCStatus(rawValue: kycStatus) ?? .notStarted)
    }
}

/// Unknown kinds fall back to `.send` and unknown statuses to `.completed`.
public extension PaymentTransactionDTO {
    func toDomain() -> PaymentTransaction {
        PaymentTransaction(
            id: id,
            fromUserId: fromUserId,
            toUserId: toUserId,
            amount: amount,
            note: note,
            kind: PaymentTransactionKind(rawValue: kind) ?? .send,
            status: PaymentTransactionStatus(rawValue: status) ?? .completed,
            conversationId: conversationId,
            createdAt: ISO8601.date(from: createdAt)
        )
    }
}
