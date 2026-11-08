import Foundation
import Observation
import Core
import Mock

/// Edits the user's close-friends list, which gates who sees stories posted with `.closeFriends` privacy.
@MainActor
@Observable
final class CloseFriendsViewModel {
    /// Makes `load()` and `save()` no-ops in previews. Not observed because the UI never reads it.
    @ObservationIgnored private var isPreview = false
    /// Everyone except the current user.
    private(set) var candidates: [User] = []
    /// Working copy of the list; only persisted by `save()`.
    var selectedIds: Set<String> = []

    private let storyRepository: IStoryRepository
    private let userRepository: IUserRepository

    init(storyRepository: IStoryRepository = StoryRepository(), userRepository: IUserRepository = UserRepository()) {
        self.storyRepository = storyRepository
        self.userRepository = userRepository
    }

    /// Loads candidates and the saved selection. Any failure leaves an empty candidate list with no error shown.
    func load() async {
        guard !isPreview else { return }
        do {
            let me = try await userRepository.currentUser()
            candidates = try await userRepository.allUsers().filter { $0.id != me.id }
            selectedIds = Set(try await storyRepository.closeFriendIds())
        } catch {
            candidates = []
        }
    }

    func toggle(_ userId: String) {
        if selectedIds.contains(userId) {
            selectedIds.remove(userId)
        } else {
            selectedIds.insert(userId)
        }
    }

    /// Replaces the saved list with the current selection. Errors are ignored, so a failed save looks successful.
    func save() async {
        guard !isPreview else { return }
        try? await storyRepository.setCloseFriends(Array(selectedIds))
    }
}

#if DEBUG
extension CloseFriendsViewModel {
    /// `.loaded` lists friends with a couple selected; `.empty` has no candidates.
    convenience init(previewScenario scenario: PreviewScenario) {
        self.init()
        isPreview = true
        guard scenario == .loaded else { return }
        candidates = PreviewData.users.filter { $0.id != PreviewData.currentUser.id }
        selectedIds = Set(candidates.prefix(2).map(\.id))
    }
}
#endif
