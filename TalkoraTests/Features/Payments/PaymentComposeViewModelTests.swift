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
final class PaymentComposeViewModelTests: XCTestCase {
    private func makeViewModel(mode: PaymentComposeMode, repo: StubPaymentRepository) -> PaymentComposeViewModel {
        PaymentComposeViewModel(mode: mode, counterpart: makeUser("bob"), conversationId: "c1", repository: repo)
    }

    func test_canSubmit_withEmptyOrInvalidAmount_isFalse() {
        let viewModel = makeViewModel(mode: .send, repo: StubPaymentRepository())

        XCTAssertFalse(viewModel.canSubmit)
        viewModel.amountText = "abc"
        XCTAssertFalse(viewModel.canSubmit)
        viewModel.amountText = "0"
        XCTAssertFalse(viewModel.canSubmit)
        viewModel.amountText = "-5"
        XCTAssertFalse(viewModel.canSubmit)
    }

    func test_canSubmit_withPositiveAmount_isTrue() {
        let viewModel = makeViewModel(mode: .send, repo: StubPaymentRepository())
        viewModel.amountText = "12.5"

        XCTAssertEqual(viewModel.amount, 12.5)
        XCTAssertTrue(viewModel.canSubmit)
    }

    func test_submit_sendMode_success_setsDidSucceed() async {
        let repo = StubPaymentRepository()
        repo.sendMoneyResult = .success(makeTransaction("t1", from: "me", to: "bob"))
        let viewModel = makeViewModel(mode: .send, repo: repo)
        viewModel.amountText = "10"

        await viewModel.submit()

        XCTAssertTrue(viewModel.didSucceed)
        XCTAssertNil(viewModel.error)
        XCTAssertFalse(viewModel.isSubmitting)
    }

    func test_submit_requestMode_success_setsDidSucceed() async {
        let repo = StubPaymentRepository()
        repo.requestMoneyResult = .success(makeTransaction("t1", from: "me", to: "bob", kind: .request))
        let viewModel = makeViewModel(mode: .request, repo: repo)
        viewModel.amountText = "10"
        viewModel.note = "  lunch  "

        await viewModel.submit()

        XCTAssertTrue(viewModel.didSucceed)
    }

    func test_submit_failure_setsError() async {
        let viewModel = makeViewModel(mode: .send, repo: StubPaymentRepository())
        viewModel.amountText = "10"

        await viewModel.submit()

        XCTAssertFalse(viewModel.didSucceed)
        XCTAssertNotNil(viewModel.error)
        XCTAssertFalse(viewModel.isSubmitting)
    }

    func test_submit_withInvalidAmount_doesNothing() async {
        let repo = StubPaymentRepository()
        repo.sendMoneyResult = .success(makeTransaction("t1", from: "me", to: "bob"))
        let viewModel = makeViewModel(mode: .send, repo: repo)
        viewModel.amountText = "0"

        await viewModel.submit()

        XCTAssertFalse(viewModel.didSucceed)
        XCTAssertNil(viewModel.error)
    }

    func test_mode_labels() {
        XCTAssertEqual(PaymentComposeMode.send.title, "Send Money")
        XCTAssertEqual(PaymentComposeMode.request.actionLabel, "Request")
    }
}
