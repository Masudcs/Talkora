@testable import Talkora
import Foundation
@testable import Core

final class StubPaymentRepository: IPaymentRepository {
    var walletResult: Result<Wallet, Error> = .failure(StubFailure.notConfigured)
    var submitKYCResult: Result<KYCStatus, Error> = .failure(StubFailure.notConfigured)
    var topUpResult: Result<Wallet, Error> = .failure(StubFailure.notConfigured)
    var transactionsResult: Result<[PaymentTransaction], Error> = .success([])
    var sendMoneyResult: Result<PaymentTransaction, Error> = .failure(StubFailure.notConfigured)
    var requestMoneyResult: Result<PaymentTransaction, Error> = .failure(StubFailure.notConfigured)
    var respondToRequestResult: Result<PaymentTransaction, Error> = .failure(StubFailure.notConfigured)

    func wallet() async throws -> Wallet {
        try walletResult.get()
    }

    func submitKYC(fullName: String, country: String) async throws -> KYCStatus {
        try submitKYCResult.get()
    }

    func topUp(amount: Double) async throws -> Wallet {
        try topUpResult.get()
    }

    func transactions() async throws -> [PaymentTransaction] {
        try transactionsResult.get()
    }

    func sendMoney(to userId: String, amount: Double, note: String?, conversationId: String?) async throws -> PaymentTransaction {
        try sendMoneyResult.get()
    }

    func requestMoney(from userId: String, amount: Double, note: String?, conversationId: String?) async throws -> PaymentTransaction {
        try requestMoneyResult.get()
    }

    func respondToRequest(_ transactionId: String, accept: Bool) async throws -> PaymentTransaction {
        try respondToRequestResult.get()
    }
}
