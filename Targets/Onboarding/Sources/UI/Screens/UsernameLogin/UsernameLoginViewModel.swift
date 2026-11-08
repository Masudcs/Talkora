import Foundation
import Observation
import Core
import Mock

/// Backs `UsernameLoginScreen`: validates the identifier with `LoginIdentifierValidator`; the password only has to be non-empty.
@MainActor
@Observable
final class UsernameLoginViewModel {
    var identifier: String = ""
    var password: String = ""
    private(set) var state: LoadableState<User> = .idle
    private let repository: IAuthRepository

    init(repository: IAuthRepository = AuthRepository()) {
        self.repository = repository
    }

    /// The trimmed username, or lowercased email, once the input is valid.
    var normalizedIdentifier: String? {
        try? LoginIdentifierValidator.validate(identifier).get().value
    }

    /// Explains what is wrong with the input; nil when it is empty (nothing typed yet) or valid.
    var identifierMessage: String? {
        guard !identifier.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              case .failure(let error) = LoginIdentifierValidator.validate(identifier) else { return nil }
        return LoginIdentifierValidator.message(for: error)
    }

    /// Needs a valid identifier and a non-empty password (the password is never validated or trimmed).
    var canSubmit: Bool {
        normalizedIdentifier != nil && !password.isEmpty && !state.isLoading
    }

    /// Signs in with the normalised identifier (trimmed username or lowercased email).
    func login() async {
        guard let identifier = normalizedIdentifier else { return }
        state = .loading
        do {
            let user = try await repository.login(identifier: identifier, password: password)
            state = .loaded(user)
        } catch {
            state = .failed(error.asAppError)
        }
    }
}

#if DEBUG
extension UsernameLoginViewModel {
    convenience init(previewScenario scenario: FormPreviewScenario) {
        self.init()
        switch scenario {
        case .empty: break
        case .invalid: identifier = "!!"
        case .filled: identifier = "amara"; password = "secret"
        case .submitting: identifier = "amara"; password = "secret"; state = .loading
        case .failed: identifier = "amara"; password = "wrong"; state = .failed(PreviewData.error)
        }
    }
}
#endif
