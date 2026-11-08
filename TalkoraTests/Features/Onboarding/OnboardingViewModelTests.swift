@testable import Talkora
import Foundation
import XCTest
@testable import Core
@testable import Onboarding

@MainActor
final class OnboardingViewModelTests: XCTestCase {
    private func makeUser(_ id: String, _ name: String = "User", bio: String = "", avatarURL: URL? = nil) -> User {
        User(id: id, displayName: name, handle: "@\(id)", avatarURL: avatarURL, status: .online, createdAt: Date(), bio: bio)
    }

    private func makeChallenge(_ id: String = "c1", hint: String? = nil) -> OTPChallenge {
        OTPChallenge(id: id, phoneNumber: "+8801712345678", expiresAt: Date(), debugHint: hint)
    }

    // MARK: - OTPVerificationViewModel

    private func makeOTP(_ stub: StubAuthRepository) -> OTPVerificationViewModel {
        OTPVerificationViewModel(repository: stub, challengeId: "c1", phoneNumber: "+8801712345678", debugHint: "hint")
    }

    func test_otpCanSubmit_isFalse_whenCodeNotSixDigits() {
        let viewModel = makeOTP(StubAuthRepository())
        viewModel.code = "12345"
        XCTAssertFalse(viewModel.canSubmit)
        viewModel.code = "1234567"
        XCTAssertFalse(viewModel.canSubmit)
    }

    func test_otpCanSubmit_isTrue_whenCodeHasSixDigits() {
        let viewModel = makeOTP(StubAuthRepository())
        viewModel.code = "123456"
        XCTAssertTrue(viewModel.canSubmit)
    }

    func test_otpVerify_success_updatesStateToLoaded() async {
        let stub = StubAuthRepository()
        stub.verifyOTPResult = .success(makeUser("u1"))
        let viewModel = makeOTP(stub)
        viewModel.code = "123456"

        await viewModel.verify()

        XCTAssertEqual(viewModel.verifyState.value?.id, "u1")
    }

    func test_otpVerify_failure_updatesStateToFailed() async {
        let stub = StubAuthRepository()
        stub.verifyOTPResult = .failure(StubFailure.notConfigured)
        let viewModel = makeOTP(stub)
        viewModel.code = "123456"

        await viewModel.verify()

        XCTAssertNotNil(viewModel.verifyState.error)
    }

    func test_otpResend_success_updatesChallengeAndClearsCode() async {
        let stub = StubAuthRepository()
        stub.resendOTPResult = .success(makeChallenge("c2", hint: "new hint"))
        let viewModel = makeOTP(stub)
        viewModel.code = "123456"

        await viewModel.resend()

        XCTAssertEqual(viewModel.challengeId, "c2")
        XCTAssertEqual(viewModel.debugHint, "new hint")
        XCTAssertEqual(viewModel.code, "")
        XCTAssertEqual(viewModel.resendState.value?.id, "c2")
    }

    func test_otpResend_failure_keepsChallengeAndSetsFailed() async {
        let stub = StubAuthRepository()
        stub.resendOTPResult = .failure(StubFailure.notConfigured)
        let viewModel = makeOTP(stub)
        viewModel.code = "123456"

        await viewModel.resend()

        XCTAssertEqual(viewModel.challengeId, "c1")
        XCTAssertEqual(viewModel.code, "123456")
        XCTAssertNotNil(viewModel.resendState.error)
    }

    // MARK: - PINSetupViewModel

    /// An isolated session so tests never touch the app's real `UserDefaults`.
    private func makeSession() -> AuthSessionStore {
        AuthSessionStore(defaults: UserDefaults(suiteName: "pin-setup-tests-\(UUID().uuidString)") ?? .standard)
    }

    func test_pinCanSubmit_isFalse_whenPinNotFourDigits() {
        let viewModel = PINSetupViewModel(userId: "u1", repository: StubAuthRepository(), session: makeSession())
        viewModel.pin = "123"
        viewModel.confirmPin = "123"
        XCTAssertFalse(viewModel.canSubmit)
    }

    func test_pinCanSubmit_isFalse_whenPinsDiffer() {
        let viewModel = PINSetupViewModel(userId: "u1", repository: StubAuthRepository(), session: makeSession())
        viewModel.pin = "1234"
        viewModel.confirmPin = "1235"
        XCTAssertFalse(viewModel.canSubmit)
    }

    func test_pinCanSubmit_isTrue_whenPinsMatchAndFourDigits() {
        let viewModel = PINSetupViewModel(userId: "u1", repository: StubAuthRepository(), session: makeSession())
        viewModel.pin = "1234"
        viewModel.confirmPin = "1234"
        XCTAssertTrue(viewModel.canSubmit)
    }

    func test_pinsMismatch_onlyWhenConfirmNonEmptyAndDifferent() {
        let viewModel = PINSetupViewModel(userId: "u1", repository: StubAuthRepository(), session: makeSession())
        viewModel.pin = "1234"
        XCTAssertFalse(viewModel.pinsMismatch)
        viewModel.confirmPin = "12"
        XCTAssertTrue(viewModel.pinsMismatch)
        viewModel.confirmPin = "1234"
        XCTAssertFalse(viewModel.pinsMismatch)
    }

    func test_pinSave_success_updatesStateToLoaded() async {
        let stub = StubAuthRepository()
        let viewModel = PINSetupViewModel(userId: "u1", repository: stub, session: makeSession())
        viewModel.pin = "1234"
        viewModel.confirmPin = "1234"

        await viewModel.savePIN()

        XCTAssertEqual(viewModel.state.value, true)
    }

    func test_pinSave_failure_updatesStateToFailed() async {
        let stub = StubAuthRepository()
        stub.setAppLockPINResult = .failure(StubFailure.notConfigured)
        let viewModel = PINSetupViewModel(userId: "u1", repository: stub, session: makeSession())
        viewModel.pin = "1234"
        viewModel.confirmPin = "1234"

        await viewModel.savePIN()

        XCTAssertNotNil(viewModel.state.error)
    }

    func test_pinSkip_success_updatesStateToLoaded() async {
        let viewModel = PINSetupViewModel(userId: "u1", repository: StubAuthRepository(), session: makeSession())

        await viewModel.skip()

        XCTAssertEqual(viewModel.state.value, true)
    }

    func test_pinSkip_failure_updatesStateToFailed() async {
        let stub = StubAuthRepository()
        stub.setAppLockPINResult = .failure(StubFailure.notConfigured)
        let viewModel = PINSetupViewModel(userId: "u1", repository: stub, session: makeSession())

        await viewModel.skip()

        XCTAssertNotNil(viewModel.state.error)
    }

    // MARK: - ProfileSetupViewModel

    func test_profileSetupCanSubmit_isFalse_whenNameBlank() {
        let viewModel = ProfileSetupViewModel(repository: StubAuthRepository(), userId: "u1")
        XCTAssertFalse(viewModel.canSubmit)
        viewModel.displayName = "   "
        XCTAssertFalse(viewModel.canSubmit)
    }

    func test_profileSetupCanSubmit_isTrue_whenNameProvided() {
        let viewModel = ProfileSetupViewModel(repository: StubAuthRepository(), userId: "u1", initialName: "Ava")
        XCTAssertEqual(viewModel.displayName, "Ava")
        XCTAssertTrue(viewModel.canSubmit)
    }

    func test_profileSetupSave_success_updatesStateToLoaded() async {
        let stub = StubAuthRepository()
        stub.completeProfileResult = .success(makeUser("u1", "Ava"))
        let viewModel = ProfileSetupViewModel(repository: stub, userId: "u1", initialName: "Ava")

        await viewModel.save()

        XCTAssertEqual(viewModel.state.value?.displayName, "Ava")
    }

    func test_profileSetupSave_failure_updatesStateToFailed() async {
        let stub = StubAuthRepository()
        stub.completeProfileResult = .failure(StubFailure.notConfigured)
        let viewModel = ProfileSetupViewModel(repository: stub, userId: "u1", initialName: "Ava")

        await viewModel.save()

        XCTAssertNotNil(viewModel.state.error)
    }

    // MARK: - QRLoginViewModel

    func test_qrSimulateScan_success_updatesStateAndUsesQRSessionLogin() async {
        let stub = StubAuthRepository()
        stub.loginResult = .success(makeUser("u1"))
        let viewModel = QRLoginViewModel(repository: stub)

        await viewModel.simulateScan()

        XCTAssertEqual(viewModel.state.value?.id, "u1")
        XCTAssertEqual(stub.loginCallCount, 1)
        XCTAssertEqual(stub.lastLoginIdentifier, "qr-session")
    }

    func test_qrSimulateScan_failure_updatesStateToFailed() async {
        let stub = StubAuthRepository()
        stub.loginResult = .failure(StubFailure.notConfigured)
        let viewModel = QRLoginViewModel(repository: stub)

        await viewModel.simulateScan()

        XCTAssertNotNil(viewModel.state.error)
    }
}
