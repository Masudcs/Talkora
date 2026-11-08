import Foundation
import Observation
import Core
import Mock

/// Backs `ProfileSetupScreen`: saves the display name for `userId` via `completeProfile`.
@MainActor
@Observable
final class ProfileSetupViewModel {
    var displayName: String
    private(set) var state: LoadableState<User> = .idle
    private let repository: IAuthRepository
    let userId: String

    init(repository: IAuthRepository = AuthRepository(), userId: String, initialName: String = "") {
        self.repository = repository
        self.userId = userId
        self.displayName = initialName
    }

    /// The name must contain something other than spaces.
    var canSubmit: Bool {
        !displayName.trimmingCharacters(in: .whitespaces).isEmpty && !state.isLoading
    }

    /// Sends `displayName` as typed; trimming is only applied to the `canSubmit` check, not to the saved value.
    func save() async {
        state = .loading
        do {
            let user = try await repository.completeProfile(userId: userId, displayName: displayName)
            state = .loaded(user)
        } catch {
            state = .failed(error.asAppError)
        }
    }
}

#if DEBUG
extension ProfileSetupViewModel {
    convenience init(previewScenario scenario: FormPreviewScenario) {
        self.init(userId: PreviewData.currentUser.id)
        switch scenario {
        case .empty, .invalid: break
        case .filled: displayName = "Amara Chen"
        case .submitting: displayName = "Amara Chen"; state = .loading
        case .failed: displayName = "Amara Chen"; state = .failed(PreviewData.error)
        }
    }
}
#endif
