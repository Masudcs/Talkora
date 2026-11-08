import Foundation
import Observation
import Core
import Mock

/// Backs `OTPVerificationScreen`: verifies the 6-digit code and resends it.
@MainActor
@Observable
final class OTPVerificationViewModel {
    var code: String = ""
    private(set) var verifyState: LoadableState<User> = .idle
    private(set) var resendState: LoadableState<OTPChallenge> = .idle
    let phoneNumber: String
    /// Mutable because a resend can return a new challenge; always use the latest id to verify.
    private(set) var challengeId: String
    /// Demo-code hint for non-production builds; refreshed with each resend.
    private(set) var debugHint: String?
    private let repository: IAuthRepository

    init(repository: IAuthRepository = AuthRepository(), challengeId: String, phoneNumber: String, debugHint: String?) {
        self.repository = repository
        self.challengeId = challengeId
        self.phoneNumber = phoneNumber
        self.debugHint = debugHint
    }

    /// A code is submittable only when it is exactly 6 characters.
    var canSubmit: Bool {
        code.count == 6 && !verifyState.isLoading
    }

    /// Verifies `code` against the current challenge. `verifyState` becomes `.loaded(user)` on success; the repository reports any failure as an invalid-code error.
    func verify() async {
        verifyState = .loading
        do {
            let user = try await repository.verifyOTP(challengeId: challengeId, code: code)
            verifyState = .loaded(user)
        } catch {
            verifyState = .failed(error.asAppError)
        }
    }

    /// Asks for a fresh code, adopts the returned challenge and clears the entered code.
    func resend() async {
        resendState = .loading
        do {
            let challenge = try await repository.resendOTP(challengeId: challengeId)
            challengeId = challenge.id
            debugHint = challenge.debugHint
            code = ""
            resendState = .loaded(challenge)
        } catch {
            resendState = .failed(error.asAppError)
        }
    }
}

#if DEBUG
extension OTPVerificationViewModel {
    convenience init(previewScenario scenario: FormPreviewScenario) {
        self.init(challengeId: "preview-challenge", phoneNumber: "+8801712345678", debugHint: "Demo code: 123456")
        switch scenario {
        case .empty: break
        case .invalid: code = "123"
        case .filled: code = "123456"
        case .submitting: code = "123456"; verifyState = .loading
        case .failed: code = "000000"; verifyState = .failed(PreviewData.error)
        }
    }
}
#endif
