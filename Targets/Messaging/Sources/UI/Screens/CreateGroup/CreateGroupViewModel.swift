import Foundation
import Observation
import Core
import Mock

@MainActor
@Observable
final class CreateGroupViewModel {
    var title: String = ""
    var description: String = ""
    private(set) var candidates: [User] = []
    var selectedUserIds: Set<String> = []
    private(set) var state: LoadableState<Conversation> = .idle

    @ObservationIgnored private var isPreview = false
    private let chatRepository: IGroupRepository
    private let userRepository: IUserRepository

    init(chatRepository: IGroupRepository = ChatRepository(), userRepository: IUserRepository = UserRepository()) {
        self.chatRepository = chatRepository
        self.userRepository = userRepository
    }

    var canCreate: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty && !selectedUserIds.isEmpty && !state.isLoading
    }

    func loadCandidates() async {
        guard !isPreview else { return }
        do {
            let me = try await userRepository.currentUser()
            candidates = try await userRepository.allUsers().filter { $0.id != me.id }
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

    func create() async {
        state = .loading
        do {
            let conversation = try await chatRepository.createGroup(
                title: title.trimmingCharacters(in: .whitespaces),
                description: description.trimmingCharacters(in: .whitespaces).isEmpty ? nil : description,
                memberIds: Array(selectedUserIds)
            )
            state = .loaded(conversation)
        } catch {
            state = .failed(error.asAppError)
        }
    }
}

#if DEBUG
extension CreateGroupViewModel {
    convenience init(previewScenario scenario: FormPreviewScenario) {
        self.init()
        isPreview = true
        candidates = PreviewData.users.filter { $0.id != PreviewData.currentUser.id }
        let picks = Set(candidates.prefix(2).map(\.id))
        switch scenario {
        case .empty: break
        case .invalid: title = "Weekend Plans"
        case .filled: title = "Weekend Plans"; description = "Hiking and BBQ"; selectedUserIds = picks
        case .submitting: title = "Weekend Plans"; selectedUserIds = picks; state = .loading
        case .failed: title = "Weekend Plans"; selectedUserIds = picks; state = .failed(PreviewData.error)
        }
    }
}
#endif
