import Foundation
import Observation
import Core
import Mock

@MainActor
@Observable
final class AddMembersViewModel {
    let conversationId: String
    private(set) var candidates: [User] = []
    var selectedUserIds: Set<String> = []
    private(set) var state: LoadableState<Conversation> = .idle

    @ObservationIgnored private var isPreview = false
    private let chatRepository: IChatRepository
    private let userRepository: IUserRepository

    init(conversationId: String, chatRepository: IChatRepository = ChatRepository(), userRepository: IUserRepository = UserRepository()) {
        self.conversationId = conversationId
        self.chatRepository = chatRepository
        self.userRepository = userRepository
    }

    var canAdd: Bool {
        !selectedUserIds.isEmpty && !state.isLoading
    }

    func loadCandidates() async {
        guard !isPreview else { return }
        do {
            let conversation = try await chatRepository.conversation(id: conversationId)
            let existingIds = Set(conversation.participantIds)
            candidates = try await userRepository.allUsers().filter { !existingIds.contains($0.id) }
        } catch {
            candidates = []
        }
    }

    func toggle(_ userId: String) {
        if selectedUserIds.contains(userId) {
            selectedUserIds.remove(userId)
        } else {
            selectedUserIds.insert(userId)
        }
    }

    func addSelectedMembers() async {
        guard canAdd else { return }
        state = .loading
        do {
            for userId in selectedUserIds {
                _ = try await chatRepository.addMember(userId, to: conversationId)
            }
            let updated = try await chatRepository.conversation(id: conversationId)
            state = .loaded(updated)
        } catch {
            state = .failed(error.asAppError)
        }
    }
}

#if DEBUG
extension AddMembersViewModel {
    /// `.empty` lists candidates with none selected; `.invalid` means everyone is already in the group.
    convenience init(previewScenario scenario: FormPreviewScenario) {
        self.init(conversationId: PreviewData.groupConversation.id)
        isPreview = true
        let all = PreviewData.users.filter { $0.id != PreviewData.currentUser.id }
        candidates = scenario == .invalid ? [] : all
        let picks = Set(all.prefix(2).map(\.id))
        switch scenario {
        case .empty, .invalid: break
        case .filled: selectedUserIds = picks
        case .submitting: selectedUserIds = picks; state = .loading
        case .failed: selectedUserIds = picks; state = .failed(PreviewData.error)
        }
    }
}
#endif
