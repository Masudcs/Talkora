import Foundation
import Observation
import Core
import Mock

/// Backs the simulated scan. A scan connects immediately (no request/accept), matching the promise on the My QR Code screen.
@MainActor
@Observable
final class ScanQRViewModel {
    @ObservationIgnored private var isPreview = false
    /// Everyone except the current user; a load failure just leaves this empty.
    private(set) var candidates: [User] = []
    private(set) var connectedUser: User?
    /// Set when `connectViaQR` fails. Not currently displayed by `ScanQRScreen`.
    private(set) var errorMessage: AppError?

    private let contactRepository: IContactRepository
    private let userRepository: IUserRepository

    init(contactRepository: IContactRepository = ContactRepository(), userRepository: IUserRepository = UserRepository()) {
        self.contactRepository = contactRepository
        self.userRepository = userRepository
    }

    func load() async {
        guard !isPreview else { return }
        do {
            let me = try await userRepository.currentUser()
            candidates = try await userRepository.allUsers().filter { $0.id != me.id }
        } catch {
            candidates = []
        }
    }

    func simulateScan(_ user: User) async {
        do {
            connectedUser = try await contactRepository.connectViaQR(userId: user.id)
        } catch {
            errorMessage = error.asAppError
        }
    }
}

#if DEBUG
extension ScanQRViewModel {
    /// `.loaded` lists the people you can "scan"; `.empty` has no candidates; `.failed`
    /// shows the post-scan "Connected" state (the screen has no loading or error UI).
    convenience init(previewScenario scenario: PreviewScenario) {
        self.init()
        isPreview = true
        let others = PreviewData.users.filter { $0.id != PreviewData.currentUser.id }
        switch scenario {
        case .loaded, .loading:
            candidates = others
        case .empty:
            candidates = []
        case .failed:
            candidates = others
            connectedUser = others.first
        }
    }
}
#endif
