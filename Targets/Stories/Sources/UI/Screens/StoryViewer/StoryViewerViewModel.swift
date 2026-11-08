import Foundation
import Observation
import Core
import Mock

/// Plays one author's stories in order. Each story auto-advances after `displayDuration`, driven by `timerTask`; tapping or the timer calls `next()`, and running past the last story sets `isFinished` so the screen dismisses.
@MainActor
@Observable
final class StoryViewerViewModel {
    /// Makes `start()` a no-op so previews do not run the timer or hit the backend. Not observed because the UI never reads it.
    @ObservationIgnored private var isPreview = false
    /// Fixed snapshot of the group being viewed; later changes to the feed do not affect an open viewer.
    let stories: [Story]
    private(set) var currentIndex: Int = 0
    /// Fill of the current segment, 0...1. Earlier segments are full and later ones empty (see the screen's `segmentProgress`).
    private(set) var progress: Double = 0
    private(set) var isFinished = false
    /// Loaded on demand for the author's own story; empty for others' stories.
    private(set) var viewers: [User] = []
    var isViewersPresented = false

    private let storyRepository: IStoryRepository
    private let currentUserId: String
    /// Handle to the running countdown so it can be cancelled on navigation, `stop()` and `deinit`. Not observed; it is never read by the UI.
    @ObservationIgnored private var timerTask: Task<Void, Never>?
    /// Seconds each story stays on screen.
    private let displayDuration: TimeInterval = 5

    init(stories: [Story], currentUserId: String, storyRepository: IStoryRepository = StoryRepository()) {
        self.stories = stories
        self.currentUserId = currentUserId
        self.storyRepository = storyRepository
    }

    /// Stops the countdown so the task does not outlive the viewer.
    deinit {
        timerTask?.cancel()
    }

    /// `nil` only for an empty `stories` array; the index is bounds-checked.
    var currentStory: Story? {
        stories.indices.contains(currentIndex) ? stories[currentIndex] : nil
    }

    /// Own stories show the viewers list and are not recorded as viewed.
    var isOwnStory: Bool {
        currentStory?.authorId == currentUserId
    }

    /// Records the first view and starts the countdown. Called when the screen appears.
    func start() {
        guard !isPreview else { return }
        markCurrentViewed()
        runTimer()
    }

    /// Cancels the countdown only; progress is kept. Called when the screen disappears.
    func stop() {
        timerTask?.cancel()
    }

    /// Moves to the next story, or finishes after the last one. Also called by the timer itself when a story runs out, so it cancels the current task before starting a new one.
    func next() {
        timerTask?.cancel()
        guard currentIndex < stories.count - 1 else {
            isFinished = true
            return
        }
        currentIndex += 1
        progress = 0
        markCurrentViewed()
        runTimer()
    }

    /// Goes back one story. On the first story it just restarts the countdown (note it does not reset `progress`).
    func previous() {
        timerTask?.cancel()
        guard currentIndex > 0 else {
            runTimer()
            return
        }
        currentIndex -= 1
        progress = 0
        runTimer()
    }

    /// Fetches who has seen the current story. Failures are swallowed and show as an empty list.
    func loadViewers() async {
        guard let story = currentStory else { return }
        viewers = (try? await storyRepository.viewers(of: story.id)) ?? []
    }

    /// Ticks every 50 ms and updates `progress` until `displayDuration` elapses, then advances. Elapsed time is summed from the sleep step, not measured from the clock, so it drifts slightly. A cancelled task returns without advancing.
    private func runTimer() {
        timerTask = Task {
            let step: TimeInterval = 0.05
            var elapsed: TimeInterval = 0
            while !Task.isCancelled, elapsed < displayDuration {
                try? await Task.sleep(nanoseconds: UInt64(step * 1_000_000_000))
                elapsed += step
                progress = min(elapsed / displayDuration, 1)
            }
            guard !Task.isCancelled else { return }
            next()
        }
    }

    /// Fire-and-forget view receipt. Skips the author's own stories; the local `Story.viewerIds` is not updated, so the status list only reflects the view after the next `load()`.
    private func markCurrentViewed() {
        guard let story = currentStory, story.authorId != currentUserId else { return }
        Task { try? await storyRepository.markViewed(story.id) }
    }
}

#if DEBUG
extension StoryViewerViewModel {
    convenience init(forPreview: Bool = true) {
        self.init(stories: PreviewData.stories, currentUserId: PreviewData.currentUser.id)
        isPreview = true
    }
}
#endif
