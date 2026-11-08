import Foundation
import Observation
import Core
import Mock

/// Backs `SetAppLockPINSheet`: validates a new PIN with its confirmation and stores it. Used both to enable app lock and to change the PIN.
@MainActor
@Observable
final class SetAppLockPINViewModel {
    var pin = ""
    var confirmPin = ""
    private(set) var isSaving = false
    private(set) var error: AppError?

    private let authRepository: IAuthRepository

    init(authRepository: IAuthRepository = AuthRepository()) {
        self.authRepository = authRepository
    }

    var pinsMismatch: Bool {
        !confirmPin.isEmpty && pin != confirmPin
    }

    /// Needs a full-length PIN (`PINFormat.length`) that matches the confirmation.
    var canSubmit: Bool {
        pin.count == PINFormat.length && pin == confirmPin && !isSaving
    }

    /// Called from the field's `onChange`: strips non-digits and caps the length.
    func pinChanged() {
        pin = PINFormat.sanitize(pin)
    }

    func confirmPinChanged() {
        confirmPin = PINFormat.sanitize(confirmPin)
    }

    /// Returns `true` when the PIN was saved.
    func save() async -> Bool {
        isSaving = true
        defer { isSaving = false }
        do {
            try await authRepository.setAppLockPIN(pin)
            return true
        } catch {
            self.error = error.asAppError
            return false
        }
    }
}

#if DEBUG
extension SetAppLockPINViewModel {
    convenience init(previewScenario scenario: FormPreviewScenario) {
        self.init()
        switch scenario {
        case .empty: break
        case .invalid: pin = "1234"; confirmPin = "12"
        case .filled: pin = "1234"; confirmPin = "1234"
        case .submitting: pin = "1234"; confirmPin = "1234"; isSaving = true
        case .failed: pin = "1234"; confirmPin = "1234"; error = PreviewData.error
        }
    }
}
#endif
