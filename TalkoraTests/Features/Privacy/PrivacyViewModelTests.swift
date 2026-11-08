@testable import Talkora
import Foundation
import XCTest
@testable import Core
@testable import Privacy

@MainActor
final class AppLockViewModelTests: XCTestCase {
    func test_pinChanged_keepsOnlyFirstFourDigits() {
        let viewModel = AppLockViewModel(authRepository: StubAuthRepository(), appLock: AppLockManager())
        viewModel.pin = "12a34567"

        viewModel.pinChanged()

        XCTAssertEqual(viewModel.pin, "1234")
        XCTAssertTrue(viewModel.canSubmit)
    }

    func test_unlock_wrongPin_setsErrorAndClearsPin() async {
        let stub = StubAuthRepository()
        stub.verifyAppLockPINResult = .success(false)
        let appLock = AppLockManager()
        appLock.lockNow()
        let viewModel = AppLockViewModel(authRepository: stub, appLock: appLock)
        viewModel.pin = "0000"

        await viewModel.unlock()

        XCTAssertEqual(viewModel.errorMessage, "Incorrect PIN.")
        XCTAssertEqual(viewModel.pin, "")
        XCTAssertTrue(appLock.isLocked)
    }

    func test_unlock_correctPin_unlocksApp() async {
        let stub = StubAuthRepository()
        stub.verifyAppLockPINResult = .success(true)
        let appLock = AppLockManager()
        appLock.lockNow()
        let viewModel = AppLockViewModel(authRepository: stub, appLock: appLock)
        viewModel.pin = "1234"

        await viewModel.unlock()

        XCTAssertNil(viewModel.errorMessage)
        XCTAssertFalse(appLock.isLocked)
    }
}

@MainActor
final class SetAppLockPINViewModelTests: XCTestCase {
    func test_canSubmit_requiresMatchingFourDigitPins() {
        let viewModel = SetAppLockPINViewModel(authRepository: StubAuthRepository())
        viewModel.pin = "1234"
        viewModel.confirmPin = "1235"
        XCTAssertTrue(viewModel.pinsMismatch)
        XCTAssertFalse(viewModel.canSubmit)

        viewModel.confirmPin = "1234"
        XCTAssertFalse(viewModel.pinsMismatch)
        XCTAssertTrue(viewModel.canSubmit)
    }

    func test_save_success_returnsTrue() async {
        let stub = StubAuthRepository()
        stub.setAppLockPINResult = .success(())
        let viewModel = SetAppLockPINViewModel(authRepository: stub)
        viewModel.pin = "1234"
        viewModel.confirmPin = "1234"

        let saved = await viewModel.save()

        XCTAssertTrue(saved)
        XCTAssertNil(viewModel.error)
    }

    func test_save_failure_returnsFalseAndSetsError() async {
        let stub = StubAuthRepository()
        stub.setAppLockPINResult = .failure(StubFailure.notConfigured)
        let viewModel = SetAppLockPINViewModel(authRepository: stub)
        viewModel.pin = "1234"
        viewModel.confirmPin = "1234"

        let saved = await viewModel.save()

        XCTAssertFalse(saved)
        XCTAssertNotNil(viewModel.error)
    }
}
