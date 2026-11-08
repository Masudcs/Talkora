import Foundation
import Observation
import Core
import Mock

/// Loads the current user, from whom the QR payload is derived.
@MainActor
@Observable
final class MyQRCodeViewModel {
    @ObservationIgnored private var isPreview = false
    private(set) var state: LoadableState<User> = .idle

    private let userRepository: IUserRepository

    init(userRepository: IUserRepository = UserRepository()) {
        self.userRepository = userRepository
    }

    /// The payload another user's scanner reads to connect instantly.
    var qrPayload: String? {
        state.value.map { "talkora://contact/\($0.id)" }
    }

    func load() async {
        guard !isPreview else { return }
        state = .loading
        do {
            state = .loaded(try await userRepository.currentUser())
        } catch {
            state = .failed(error.asAppError)
        }
    }
}

#if DEBUG
extension MyQRCodeViewModel {
    convenience init(previewScenario scenario: PreviewScenario) {
        self.init()
        isPreview = true
        switch scenario {
        case .loaded: state = .loaded(PreviewData.currentUser)
        case .loading: state = .loading
        case .empty: state = .idle
        case .failed: state = .failed(PreviewData.error)
        }
    }
}
#endif
