import Foundation
import Observation
import Core
import Mock

/// Backs `PhoneEntryScreen`: validates the number with `PhoneNumberValidator` and requests an OTP challenge.
@MainActor
@Observable
final class PhoneEntryViewModel {
    var phoneNumber: String = ""
    private(set) var state: LoadableState<OTPChallenge> = .idle
    private let repository: IAuthRepository

    init(repository: IAuthRepository = AuthRepository()) {
        self.repository = repository
    }

    /// The number in `+8801XXXXXXXXX` form, or nil while the input isn't a valid mobile number.
    var normalizedPhoneNumber: String? {
        try? PhoneNumberValidator.validate(phoneNumber).get()
    }

    /// Explains what is wrong with the input; nil when it is empty (nothing typed yet) or valid.
    var validationMessage: String? {
        guard !phoneNumber.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              case .failure(let error) = PhoneNumberValidator.validate(phoneNumber) else { return nil }
        return PhoneNumberValidator.message(for: error)
    }

    var canSubmit: Bool {
        normalizedPhoneNumber != nil && !state.isLoading
    }

    /// Requests an OTP for the normalised number; no-op while the input is invalid.
    func sendCode() async {
        guard let number = normalizedPhoneNumber else { return }
        state = .loading
        do {
            let challenge = try await repository.requestOTP(phoneNumber: number)
            state = .loaded(challenge)
        } catch {
            state = .failed(error.asAppError)
        }
    }
}

#if DEBUG
extension PhoneEntryViewModel {
    convenience init(previewScenario scenario: FormPreviewScenario) {
        self.init()
        switch scenario {
        case .empty: break
        case .invalid: phoneNumber = "123"
        case .filled: phoneNumber = "01712345678"
        case .submitting: phoneNumber = "01712345678"; state = .loading
        case .failed: phoneNumber = "01712345678"; state = .failed(PreviewData.error)
        }
    }
}
#endif
