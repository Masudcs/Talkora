import Foundation

/// Wire-format money transfer or request. `kind` is "send" | "request"; `status` is "completed" | "pendingAcceptance" | "declined".
public struct PaymentTransactionDTO: Codable, Sendable, Hashable {
    public let id: String
    public let fromUserId: String
    public let toUserId: String
    public let amount: Double
    public let note: String?
    public let kind: String
    public let status: String
    public let conversationId: String?
    public let createdAt: String

    public init(id: String, fromUserId: String, toUserId: String, amount: Double, note: String?, kind: String, status: String, conversationId: String?, createdAt: String) {
        self.id = id
        self.fromUserId = fromUserId
        self.toUserId = toUserId
        self.amount = amount
        self.note = note
        self.kind = kind
        self.status = status
        self.conversationId = conversationId
        self.createdAt = createdAt
    }

    public func with(status: String) -> PaymentTransactionDTO {
        PaymentTransactionDTO(id: id, fromUserId: fromUserId, toUserId: toUserId, amount: amount, note: note, kind: kind, status: status, conversationId: conversationId, createdAt: createdAt)
    }
}
