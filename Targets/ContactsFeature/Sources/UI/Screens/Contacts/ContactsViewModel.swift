import Foundation
import Observation
import Core
import Mock

/// State for the Contacts tab: discoverability, pending-request badge count and the user's connections.
@MainActor
@Observable
final class ContactsViewModel {
    @ObservationIgnored private var isPreview = false
    private(set) var discoverability: DiscoverabilityPrivacy = .everyone
    /// Drives the badge on the Requests row; refreshed on `load()` and after a simulated request.
    private(set) var incomingRequestCount: Int = 0
    private(set) var state: LoadableState<[User]> = .idle
    private(set) var currentUserId: String = ""
    /// One-shot navigation signal set by `startChat`; the screen consumes it and calls `clearNavigation()`.
    private(set) var navigateToConversationId: String?

    private let contactRepository: IContactRepository
    private let chatRepository: IConversationRepository
    private let userRepository: IUserRepository

    init(contactRepository: IContactRepository = ContactRepository(), chatRepository: IConversationRepository = ChatRepository(), userRepository: IUserRepository = UserRepository()) {
        self.contactRepository = contactRepository
        self.chatRepository = chatRepository
        self.userRepository = userRepository
    }

    /// Empty connections is still a valid, renderable screen, so it stays `.loaded([])` rather than `.empty`.
    var connections: [User] {
        state.value ?? []
    }

    /// Only shows `.loading` on first load, so reloads on reappearance (`.task` re-runs) keep the existing list visible. Any failed call fails the whole screen.
    func load() async {
        guard !isPreview else { return }
        if state.value == nil { state = .loading }
        do {
            currentUserId = try await userRepository.currentUser().id
            discoverability = try await contactRepository.discoverability()
            incomingRequestCount = try await contactRepository.incomingRequests().count
            state = .loaded(try await contactRepository.myConnections())
        } catch {
            state = .failed(error.asAppError)
        }
    }

    /// Not optimistic: the UI value changes only after the repository confirms; a failure is silently ignored and the old value stays.
    func updateDiscoverability(_ value: DiscoverabilityPrivacy) async {
        if let updated = try? await contactRepository.setDiscoverability(value) {
            discoverability = updated
        }
    }

    func simulateIncomingRequest() async {
        _ = try? await contactRepository.simulateIncomingRequest()
        incomingRequestCount = (try? await contactRepository.incomingRequests().count) ?? incomingRequestCount
    }

    /// Finds or creates the 1:1 conversation; on failure the id stays nil and nothing is pushed.
    func startChat(with user: User) async {
        navigateToConversationId = try? await chatRepository.findOrCreateDirectConversation(with: user.id).id
    }

    func clearNavigation() {
        navigateToConversationId = nil
    }
}

#if DEBUG
extension ContactsViewModel {
    convenience init(previewScenario scenario: PreviewScenario) {
        self.init()
        isPreview = true
        currentUserId = PreviewData.currentUser.id
        incomingRequestCount = 2
        let others = PreviewData.users.filter { $0.id != PreviewData.currentUser.id }
        switch scenario {
        case .loaded: state = .loaded(others)
        case .empty: state = .loaded([])
        case .loading: state = .loading
        case .failed: state = .failed(PreviewData.error)
        }
    }
}
#endif
