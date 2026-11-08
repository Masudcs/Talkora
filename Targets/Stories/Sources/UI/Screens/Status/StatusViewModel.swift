import Foundation
import Observation
import Core
import Mock

/// Feed for the Status tab: the user's own active stories plus others' stories grouped by author. Which stories are visible (expiry, privacy, close friends) is decided by the repository/backend, not here.
@MainActor
@Observable
final class StatusViewModel {
    /// Makes `load()` a no-op so preview state is kept. Not observed because the UI never reads it.
    @ObservationIgnored private var isPreview = false
    private(set) var state: LoadableState<[Story]> = .idle
    /// Splits own vs others' stories; empty until the first `load()`.
    private(set) var currentUserId: String = ""
    /// Author display names by id, cached across reloads.
    private(set) var userNames: [String: String] = [:]

    private let storyRepository: IStoryRepository
    private let userRepository: IUserRepository

    init(storyRepository: IStoryRepository = StoryRepository(), userRepository: IUserRepository = UserRepository()) {
        self.storyRepository = storyRepository
        self.userRepository = userRepository
    }

    /// A loaded-but-empty list is still `.loaded([])` so the "My Status" row keeps rendering.
    private var stories: [Story] {
        state.value ?? []
    }

    /// The user's own live stories. Highlighted ones are excluded because they are permanent and would otherwise keep "My Status" looking active forever.
    var myActiveStories: [Story] {
        stories.filter { $0.authorId == currentUserId && !$0.isHighlighted }
    }

    /// One entry per author, stories oldest first (playback order), authors sorted by name (authors with no resolved name sort first).
    var othersStoriesGrouped: [(author: String, stories: [Story])] {
        let others = stories.filter { $0.authorId != currentUserId }
        let grouped = Dictionary(grouping: others, by: \.authorId)
        return grouped
            .map { (author: $0.key, stories: $0.value.sorted { $0.createdAt < $1.createdAt }) }
            .sorted { (userNames[$0.author] ?? "") < (userNames[$1.author] ?? "") }
    }

    /// Falls back to "Unknown" if the author lookup failed.
    func name(for userId: String) -> String {
        userNames[userId] ?? "Unknown"
    }

    /// Drives the ring colour: grey once every story in the group has been seen by the current user.
    func hasViewedAll(_ group: [Story]) -> Bool {
        group.allSatisfy { $0.viewerIds.contains(currentUserId) }
    }

    /// Fetches the user, then active stories, then any author names not cached, and only then publishes the list so rows never render with missing names. A failure replaces the list with `.failed`, even on a reload.
    func load() async {
        guard !isPreview else { return }
        // Re-loads (e.g. after creating a story) keep showing the current list instead of flashing a spinner.
        if state.value == nil { state = .loading }
        do {
            currentUserId = try await userRepository.currentUser().id
            let items = try await storyRepository.activeStories()
            for story in items where userNames[story.authorId] == nil {
                if let user = try? await userRepository.user(id: story.authorId) {
                    userNames[story.authorId] = user.displayName
                }
            }
            state = .loaded(items)
        } catch {
            state = .failed(error.asAppError)
        }
    }

    /// Deletes remotely and removes the story locally regardless of whether the call succeeded (the error is ignored).
    func deleteMyStory(_ story: Story) async {
        try? await storyRepository.deleteStory(story.id)
        state = .loaded(stories.filter { $0.id != story.id })
    }
}

#if DEBUG
extension StatusViewModel {
    convenience init(previewScenario scenario: PreviewScenario) {
        self.init()
        isPreview = true
        currentUserId = PreviewData.currentUser.id
        userNames = PreviewData.userNames
        switch scenario {
        case .loaded: state = .loaded(PreviewData.stories)
        case .empty: state = .loaded([])
        case .loading: state = .loading
        case .failed: state = .failed(PreviewData.error)
        }
    }
}
#endif
