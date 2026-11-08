@testable import Talkora
import Foundation
import XCTest
@testable import Core
@testable import Payments

private func makeUser(_ id: String, _ name: String = "User") -> User {
    User(id: id, displayName: name, handle: "@\(id)", avatarURL: nil, status: .online, createdAt: Date())
}

private func makeTransaction(_ id: String, from: String, to: String, kind: PaymentTransactionKind = .send) -> PaymentTransaction {
    PaymentTransaction(id: id, fromUserId: from, toUserId: to, amount: 10, note: nil, kind: kind,
                       status: .completed, conversationId: nil, createdAt: Date())
}

@MainActor
final class WalletViewModelTests: XCTestCase {
    private func makeViewModel(repo: StubPaymentRepository, users: StubUserRepository) -> WalletViewModel {
        WalletViewModel(repository: repo, userRepository: users)
    }

    private func makeUsers() -> StubUserRepository {
        let users = StubUserRepository()
        users.currentUserResult = .success(makeUser("me"))
        users.userResult = .success(makeUser("bob", "Bob"))
        return users
    }

    func test_load_success_populatesWalletTransactionsAndCounterparts() async {
        let repo = StubPaymentRepository()
        repo.walletResult = .success(Wallet(balance: 50, kycStatus: .verified))
        let txn = makeTransaction("t1", from: "me", to: "bob")
        repo.transactionsResult = .success([txn])
        let viewModel = makeViewModel(repo: repo, users: makeUsers())

        await viewModel.load()

        XCTAssertEqual(viewModel.wallet?.balance, 50)
        XCTAssertTrue(viewModel.isVerified)
        XCTAssertEqual(viewModel.currentUserId, "me")
        XCTAssertEqual(viewModel.transactions.map(\.id), ["t1"])
        XCTAssertEqual(viewModel.counterpartName(for: txn), "Bob")
    }

    func test_load_withNoTransactions_setsEmpty() async {
        let repo = StubPaymentRepository()
        repo.walletResult = .success(Wallet(balance: 0, kycStatus: .notStarted))
        let viewModel = makeViewModel(repo: repo, users: makeUsers())

        await viewModel.load()

        guard case .empty = viewModel.transactionsState else {
            return XCTFail("Expected .empty, got \(viewModel.transactionsState)")
        }
        XCTAssertFalse(viewModel.isVerified)
    }

    func test_load_transactionsFailure_setsFailed() async {
        let repo = StubPaymentRepository()
        repo.transactionsResult = .failure(StubFailure.notConfigured)
        let viewModel = makeViewModel(repo: repo, users: makeUsers())

        await viewModel.load()

        XCTAssertNotNil(viewModel.transactionsState.error)
        XCTAssertTrue(viewModel.transactions.isEmpty)
    }

    func test_counterpartName_unknownUser_fallsBackToSomeone() {
        let viewModel = makeViewModel(repo: StubPaymentRepository(), users: StubUserRepository())

        XCTAssertEqual(viewModel.counterpartName(for: makeTransaction("t1", from: "x", to: "y")), "Someone")
    }

    func test_topUp_success_reloadsWallet() async {
        let repo = StubPaymentRepository()
        repo.topUpResult = .success(Wallet(balance: 100, kycStatus: .verified))
        repo.walletResult = .success(Wallet(balance: 100, kycStatus: .verified))
        let viewModel = makeViewModel(repo: repo, users: makeUsers())

        await viewModel.topUp(amount: 100)

        XCTAssertEqual(viewModel.wallet?.balance, 100)
        XCTAssertNil(viewModel.actionError)
    }

    func test_topUp_failure_setsActionError() async {
        let viewModel = makeViewModel(repo: StubPaymentRepository(), users: makeUsers())

        await viewModel.topUp(amount: 100)

        XCTAssertNotNil(viewModel.actionError)
    }

    func test_submitKYC_success_reloadsWallet() async {
        let repo = StubPaymentRepository()
        repo.submitKYCResult = .success(.verified)
        repo.walletResult = .success(Wallet(balance: 0, kycStatus: .verified))
        let viewModel = makeViewModel(repo: repo, users: makeUsers())

        await viewModel.submitKYC(fullName: "Me", country: "US")

        XCTAssertTrue(viewModel.isVerified)
        XCTAssertNil(viewModel.actionError)
    }

    func test_submitKYC_failure_setsActionError() async {
        let viewModel = makeViewModel(repo: StubPaymentRepository(), users: makeUsers())

        await viewModel.submitKYC(fullName: "Me", country: "US")

        XCTAssertNotNil(viewModel.actionError)
    }
}
