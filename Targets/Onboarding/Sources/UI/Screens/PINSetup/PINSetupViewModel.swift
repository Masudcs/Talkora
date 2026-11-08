import Foundation
import Observation
import Core
import Mock

/// Backs `PINSetupScreen`, the final onboarding step. Both saving a PIN and skipping end onboarding by calling `AuthSessionStore.completeOnboarding`, which switches the app to the main UI.
@MainActor
@Observable
final class PINSetupViewModel {
    var pin: String = ""
    var confirmPin: String = ""
    private(set) var state: LoadableState<Bool> = .idle
    let userId: String
    private let repository: IAuthRepository
    private let session: AuthSessionStore

    init(userId: String, repository: IAuthRepository = AuthRepository(), session: AuthSessionStore = .shared) {
        self.userId = userId
        self.repository = repository
        self.session = session
    }

    /// Needs a full-length PIN (`PINFormat.length`, 4 digits) that matches the confirmation.
    var canSubmit: Bool {
        pin.count == PINFormat.length && pin == confirmPin && !state.isLoading
    }

    var pinsMismatch: Bool {
        !confirmPin.isEmpty && pin != confirmPin
    }

    /// Called from the field's `onChange`: strips non-digits and caps the length.
    func pinChanged() {
        pin = PINFormat.sanitize(pin)
    }

    func confirmPinChanged() {
        confirmPin = PINFormat.sanitize(confirmPin)
    }

    /// Stores the PIN, then completes onboarding. On failure the user stays here and `state` carries the error.
    func savePIN() async {
        state = .loading
        do {
            try await repository.setAppLockPIN(pin)
            state = .loaded(true)
            session.completeOnboarding(userId: userId)
        } catch {
            state = .failed(error.asAppError)
        }
    }

    /// Passing a nil PIN records "no app lock"; onboarding still completes.
    func skip() async {
        state = .loading
        do {
            try await repository.setAppLockPIN(nil)
            state = .loaded(true)
            session.completeOnboarding(userId: userId)
        } catch {
            state = .failed(error.asAppError)
        }
    }
}

#if DEBUG
extension PINSetupViewModel {
    convenience init(previewScenario scenario: FormPreviewScenario) {
        self.init(userId: PreviewData.currentUser.id, session: AuthSessionStore(defaults: PreviewData.defaults))
        switch scenario {
        case .empty: break
        case .invalid: pin = "1234"; confirmPin = "12"
        case .filled: pin = "1234"; confirmPin = "1234"
        case .submitting: pin = "1234"; confirmPin = "1234"; state = .loading
        case .failed: pin = "1234"; confirmPin = "1234"; state = .failed(PreviewData.error)
        }
    }
}
#endif
