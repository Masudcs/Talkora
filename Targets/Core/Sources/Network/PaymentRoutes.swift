import Foundation

/// Wallet, KYC, top-ups and money transfers. `sendMoney` and `requestMoney` share one body shape; `respond` accepts or declines a pending request.
public enum PaymentRoutes: EndpointConvertible {
    case wallet
    case submitKYC(fullName: String, country: String)
    case topUp(amount: Double)
    case transactions
    case sendMoney(toUserId: String, amount: Double, note: String?, conversationId: String?)
    case requestMoney(toUserId: String, amount: Double, note: String?, conversationId: String?)
    case respond(transactionId: String, accept: Bool)

    public var endpoint: Endpoint {
        switch self {
        case .wallet:
            return Endpoint(path: "/wallet")
        case .submitKYC(let fullName, let country):
            return Endpoint(path: "/wallet/kyc", method: .post, body: KYCBody(fullName: fullName, country: country))
        case .topUp(let amount):
            return Endpoint(path: "/wallet/top-up", method: .post, body: TopUpBody(amount: amount))
        case .transactions:
            return Endpoint(path: "/payments")
        case .sendMoney(let toUserId, let amount, let note, let conversationId):
            return Endpoint(path: "/payments/send", method: .post, body: TransferBody(toUserId, amount, note, conversationId))
        case .requestMoney(let toUserId, let amount, let note, let conversationId):
            return Endpoint(path: "/payments/request", method: .post, body: TransferBody(toUserId, amount, note, conversationId))
        case .respond(let transactionId, let accept):
            return Endpoint(path: "/payments/\(transactionId)/respond", method: .post, body: AcceptBody(accept: accept))
        }
    }
}

// MARK: - Request bodies

/// Encodable request bodies. `TransferBody` drops an empty `note`.
public extension PaymentRoutes {
    struct KYCBody: Encodable, Sendable { let fullName: String; let country: String }
    struct TopUpBody: Encodable, Sendable { let amount: Double }
    struct AcceptBody: Encodable, Sendable { let accept: Bool }
    struct TransferBody: Encodable, Sendable {
        public let toUserId: String
        public let amount: Double
        public let note: String?
        public let conversationId: String?

        public init(_ toUserId: String, _ amount: Double, _ note: String?, _ conversationId: String?) {
            self.toUserId = toUserId
            self.amount = amount
            self.note = note?.isEmpty == false ? note : nil
            self.conversationId = conversationId
        }
    }
}
