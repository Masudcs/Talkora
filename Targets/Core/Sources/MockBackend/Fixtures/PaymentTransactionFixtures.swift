import Foundation

/// A little prior history between other users, so `u1`'s wallet screen doesn't look
/// empty on first launch even before they've sent anything themselves.
public enum PaymentTransactionFixtures {
    public static let seed: [PaymentTransactionDTO] = [
        PaymentTransactionDTO(
            id: "pay1",
            fromUserId: "u2",
            toUserId: "u5",
            amount: 45,
            note: "Concert tickets",
            kind: "send",
            status: "completed",
            conversationId: nil,
            createdAt: "2024-09-10T18:00:00Z"
        ),
    ]
}
