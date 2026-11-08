import Foundation
import Observation
import Core
import Mock

/// Pending requests plus the sender names needed to display them.
@MainActor
@Observable
final class IncomingRequestsViewModel {
    @ObservationIgnored private var isPreview = false
    private(set) var requests: [ContactRequest] = []
    /// Sender user id -> display name, cached across reloads; missing names render as "Unknown".
    private(set) var senderNames: [String: String] = [:]

    private let contactRepository: IContactRepository
    private let userRepository: IUserRepository

    init(contactRepository: IContactRepository = ContactRepository(), userRepository: IUserRepository = UserRepository()) {
        self.contactRepository = contactRepository
        self.userRepository = userRepository
    }

    func name(for request: ContactRequest) -> String {
        senderNames[request.fromUserId] ?? "Unknown"
    }

    /// Names are resolved before `requests` is assigned, so rows never appear with a placeholder name unless the lookup failed. A failed fetch shows as an empty list.
    func load() async {
        guard !isPreview else { return }
        let items = (try? await contactRepository.incomingRequests()) ?? []
        for request in items where senderNames[request.fromUserId] == nil {
            if let user = try? await userRepository.user(id: request.fromUserId) {
                senderNames[request.fromUserId] = user.displayName
            }
        }
        requests = items
    }

    /// The row is removed regardless of whether the repository call succeeded.
    func respond(_ request: ContactRequest, accept: Bool) async {
        _ = try? await contactRepository.respondToRequest(request.id, accept: accept)
        requests.removeAll { $0.id == request.id }
    }
}

#if DEBUG
extension IncomingRequestsViewModel {
    convenience init(previewScenario scenario: PreviewScenario) {
        self.init()
        isPreview = true
        requests = scenario == .loaded ? PreviewData.incomingRequests : []
        senderNames = PreviewData.userNames
    }
}
#endif
