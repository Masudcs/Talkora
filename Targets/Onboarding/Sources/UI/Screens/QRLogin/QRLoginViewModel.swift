import Foundation
import Observation
import Core
import Mock

/// Backs the QR-login placeholder screen. Real QR scanning/session-pairing is out of
/// scope for a mock backend — "Simulate Scan" exercises the same login endpoint a real
/// scan-and-pair flow would eventually call.
@MainActor
@Observable
final class QRLoginViewModel {
    private(set) var state: LoadableState<User> = .idle
    private let repository: IAuthRepository

    init(repository: IAuthRepository = AuthRepository()) {
        self.repository = repository
    }

    /// Logs in with a fixed `qr-session` identifier/password pair standing in for a paired session.
    func simulateScan() async {
        state = .loading
        do {
            let user = try await repository.login(identifier: "qr-session", password: "qr-session")
            state = .loaded(user)
        } catch {
            state = .failed(error.asAppError)
        }
    }
}

#if DEBUG
extension QRLoginViewModel {
    convenience init(previewScenario scenario: FormPreviewScenario) {
        self.init()
        switch scenario {
        case .empty, .filled, .invalid: break
        case .submitting: state = .loading
        case .failed: state = .failed(PreviewData.error)
        }
    }
}
#endif
