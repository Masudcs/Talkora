@testable import Talkora
import Foundation
import XCTest
@testable import Core
@testable import Onboarding

@MainActor
final class PhoneEntryViewModelTests: XCTestCase {
    func test_sendCode_success_updatesStateToLoaded() async {
        let stub = StubAuthRepository()
        let challenge = OTPChallenge(id: "c1", phoneNumber: "+8801712345678", expiresAt: Date(), debugHint: "Demo code: 123456")
        stub.requestOTPResult = .success(challenge)
        let viewModel = PhoneEntryViewModel(repository: stub)
        viewModel.phoneNumber = "01712345678"

        await viewModel.sendCode()

        XCTAssertEqual(viewModel.state.value?.id, "c1")
        XCTAssertEqual(stub.lastRequestedPhoneNumber, "+8801712345678")
    }

    func test_sendCode_failure_updatesStateToFailed() async {
        let stub = StubAuthRepository()
        stub.requestOTPResult = .failure(StubFailure.notConfigured)
        let viewModel = PhoneEntryViewModel(repository: stub)
        viewModel.phoneNumber = "01712345678"

        await viewModel.sendCode()

        XCTAssertNotNil(viewModel.state.error)
    }

    func test_canSubmit_isFalse_whenPhoneNumberEmpty() {
        let viewModel = PhoneEntryViewModel(repository: StubAuthRepository())
        XCTAssertFalse(viewModel.canSubmit)
    }

    func test_canSubmit_isFalse_whenNumberHasTenDigits() {
        let viewModel = PhoneEntryViewModel(repository: StubAuthRepository())
        viewModel.phoneNumber = "0171234567"

        XCTAssertFalse(viewModel.canSubmit)
        XCTAssertEqual(viewModel.validationMessage, "Enter all 11 digits of your mobile number.")
    }

    func test_validationMessage_isNil_whenNothingTypedOrNumberValid() {
        let viewModel = PhoneEntryViewModel(repository: StubAuthRepository())
        XCTAssertNil(viewModel.validationMessage)

        viewModel.phoneNumber = "01912345678"
        XCTAssertNil(viewModel.validationMessage)
        XCTAssertTrue(viewModel.canSubmit)
    }

    func test_sendCode_withInvalidNumber_shouldNotCallRepository() async {
        let stub = StubAuthRepository()
        let viewModel = PhoneEntryViewModel(repository: stub)
        viewModel.phoneNumber = "12345"

        await viewModel.sendCode()

        XCTAssertEqual(stub.requestOTPCallCount, 0)
        XCTAssertNil(viewModel.state.value)
    }
}
