@testable import Talkora
import Foundation
import XCTest
@testable import Core
@testable import Payments

@MainActor
final class KYCViewModelTests: XCTestCase {
    func test_canSubmit_requiresNameAndCountry() {
        let viewModel = KYCViewModel { _, _ in }
        XCTAssertFalse(viewModel.canSubmit)
        viewModel.fullName = "Ada Lovelace"
        XCTAssertFalse(viewModel.canSubmit)
        viewModel.country = "UK"
        XCTAssertTrue(viewModel.canSubmit)
    }

    func test_submit_forwardsValues() async {
        var received: (String, String)?
        let viewModel = KYCViewModel { received = ($0, $1) }
        viewModel.fullName = "Ada Lovelace"
        viewModel.country = "UK"

        await viewModel.submit()

        XCTAssertEqual(received?.0, "Ada Lovelace")
        XCTAssertEqual(received?.1, "UK")
        XCTAssertFalse(viewModel.isSubmitting)
    }
}

@MainActor
final class TopUpViewModelTests: XCTestCase {
    func test_canSubmit_isFalse_forInvalidOrNonPositiveAmount() {
        let viewModel = TopUpViewModel { _ in }
        viewModel.amountText = "abc"
        XCTAssertFalse(viewModel.canSubmit)
        viewModel.amountText = "0"
        XCTAssertFalse(viewModel.canSubmit)
        viewModel.amountText = "-5"
        XCTAssertFalse(viewModel.canSubmit)
    }

    func test_submit_forwardsParsedAmount() async {
        var received: Double?
        let viewModel = TopUpViewModel { received = $0 }
        viewModel.amountText = "25.5"

        await viewModel.submit()

        XCTAssertEqual(received, 25.5)
    }

    func test_submit_doesNothing_whenAmountInvalid() async {
        var called = false
        let viewModel = TopUpViewModel { _ in called = true }
        viewModel.amountText = "0"

        await viewModel.submit()

        XCTAssertFalse(called)
    }
}
