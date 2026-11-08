import Foundation

/// The wallet, KYC and money transfers, over `APIClientProtocol` — behaves the same against the mock, stubbed and live backends.
public final class PaymentRepository: IPaymentRepository {
    private let api: APIClientProtocol

    public init(api: APIClientProtocol = APIClientProvider.shared.client) {
        self.api = api
    }

    public func wallet() async throws -> Wallet {
        let dto: WalletDTO = try await api.request(PaymentRoutes.wallet)
        return dto.toDomain()
    }

    public func submitKYC(fullName: String, country: String) async throws -> KYCStatus {
        let dto: WalletDTO = try await api.request(
            PaymentRoutes.submitKYC(fullName: fullName, country: country)
        )
        return KYCStatus(rawValue: dto.kycStatus) ?? .notStarted
    }

    public func topUp(amount: Double) async throws -> Wallet {
        let dto: WalletDTO = try await api.request(
            PaymentRoutes.topUp(amount: amount)
        )
        return dto.toDomain()
    }

    public func transactions() async throws -> [PaymentTransaction] {
        let dtos: [PaymentTransactionDTO] = try await api.request(PaymentRoutes.transactions)
        return dtos.map { $0.toDomain() }
    }

    public func sendMoney(to userId: String, amount: Double, note: String?, conversationId: String?) async throws -> PaymentTransaction {
        let dto: PaymentTransactionDTO = try await api.request(
            PaymentRoutes.sendMoney(toUserId: userId, amount: amount, note: note, conversationId: conversationId)
        )
        return dto.toDomain()
    }

    public func requestMoney(from userId: String, amount: Double, note: String?, conversationId: String?) async throws -> PaymentTransaction {
        let dto: PaymentTransactionDTO = try await api.request(
            PaymentRoutes.requestMoney(toUserId: userId, amount: amount, note: note, conversationId: conversationId)
        )
        return dto.toDomain()
    }

    public func respondToRequest(_ transactionId: String, accept: Bool) async throws -> PaymentTransaction {
        let dto: PaymentTransactionDTO = try await api.request(
            PaymentRoutes.respond(transactionId: transactionId, accept: accept)
        )
        return dto.toDomain()
    }
}
