import Foundation
import Observation
import Core

/// Backs `AppLockScreen`: checks the entered PIN through `AppLockManager`, which clears the lock when it matches. There is no attempt limit or lockout.
@MainActor
@Observable
final class AppLockViewModel {
    var pin = ""
    private(set) var errorMessage: String?
    private(set) var isVerifying = false

    private let authRepository: IAuthRepository
    private let appLock: AppLockManager

    init(authRepository: IAuthRepository = AuthRepository(), appLock: AppLockManager = .shared) {
        self.authRepository = authRepository
        self.appLock = appLock
    }

    var canSubmit: Bool {
        pin.count == PINFormat.length
    }

    /// Sanitises the PIN to digits (max `PINFormat.length`) and clears any previous error as soon as the user edits.
    func pinChanged() {
        pin = PINFormat.sanitize(pin)
        errorMessage = nil
    }

    /// A failed attempt, including a repository error, shows "Incorrect PIN." and clears the field. Success needs no handling here: the manager flips `isLocked` and the shell drops the screen.
    func unlock() async {
        isVerifying = true
        defer { isVerifying = false }
        let success = await appLock.unlock(pin: pin, authRepository: authRepository)
        if !success {
            errorMessage = "Incorrect PIN."
            pin = ""
        }
    }
}

#if DEBUG
extension AppLockViewModel {
    convenience init(previewScenario scenario: FormPreviewScenario) {
        self.init(appLock: AppLockManager())
        switch scenario {
        case .empty: break
        case .invalid: pin = "12"
        case .filled: pin = "1234"
        case .submitting: pin = "1234"; isVerifying = true
        case .failed: errorMessage = "Incorrect PIN."
        }
    }
}
#endif
