import Foundation

/// Improve: one simplified KYC flow regardless of region — this is a mock payments
/// layer, so there's no reason to model real multi-region compliance complexity.
public enum KYCStatus: String, Sendable {
    case notStarted
    case verified
}

public enum PaymentTransactionKind: String, Sendable {
    case send
    case request
}

/// `pendingAcceptance` applies only to requests awaiting the payer's response.
public enum PaymentTransactionStatus: String, Sendable {
    case completed
    case pendingAcceptance
    case declined
}

/// `fromUserId`/`toUserId` mean different things depending on `kind`: for `.send`,
/// money already moved from `fromUserId` to `toUserId`. For `.request`, `fromUserId`
/// is the requester and `toUserId` is the person being asked to pay — money only
/// moves once they accept via `IPaymentRepository.respondToRequest`.
public struct PaymentTransaction: Identifiable, Hashable, Sendable {
    public let id: String
    public let fromUserId: String
    public let toUserId: String
    public let amount: Double
    public let note: String?
    public let kind: PaymentTransactionKind
    public let status: PaymentTransactionStatus
    public let conversationId: String?
    public let createdAt: Date

    public init(id: String, fromUserId: String, toUserId: String, amount: Double, note: String?, kind: PaymentTransactionKind, status: PaymentTransactionStatus, conversationId: String?, createdAt: Date) {
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
}

/// The current user's balance and verification state; sending money requires `kycStatus == .verified`.
public struct Wallet: Sendable {
    public let balance: Double
    public let kycStatus: KYCStatus

    public init(balance: Double, kycStatus: KYCStatus) {
        self.balance = balance
        self.kycStatus = kycStatus
    }
}

/// Whether the payment compose sheet is sending money or requesting it.
public enum PaymentComposeMode {
    case send
    case request

    public var title: String {
        switch self {
        case .send: return "Send Money"
        case .request: return "Request Money"
        }
    }

    public var actionLabel: String {
        switch self {
        case .send: return "Send"
        case .request: return "Request"
        }
    }
}
