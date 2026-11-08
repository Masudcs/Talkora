import Foundation
import Observation
import Core
import Mock

/// Backs the per-conversation "Media & Files" tab — Improve: one searchable place
/// instead of scrolling back through chat history to find an old attachment.
@MainActor
@Observable
final class MediaHistoryViewModel {
    let conversationId: String
    private(set) var state: LoadableState<[Message]> = .idle
    var searchQuery: String = ""

    @ObservationIgnored private var isPreview = false
    private let repository: IMediaRepository

    init(conversationId: String, repository: IMediaRepository = MediaRepository()) {
        self.conversationId = conversationId
        self.repository = repository
    }

    /// Client-side filter on attachment file name or message text (the caption); no server search.
    var filteredItems: [Message] {
        let items = state.value ?? []
        guard !searchQuery.isEmpty else { return items }
        return items.filter { message in
            guard let attachment = message.attachment else { return false }
            return attachment.fileName.localizedCaseInsensitiveContains(searchQuery)
                || message.text.localizedCaseInsensitiveContains(searchQuery)
        }
    }

    func load() async {
        guard !isPreview else { return }
        state = .loading
        do {
            let items = try await repository.mediaHistory(conversationId: conversationId)
            state = items.isEmpty ? .empty : .loaded(items)
        } catch {
            state = .failed(error.asAppError)
        }
    }
}

#if DEBUG
extension MediaHistoryViewModel {
    convenience init(previewScenario scenario: PreviewScenario) {
        self.init(conversationId: PreviewData.directConversation.id)
        isPreview = true
        state = scenario.state(PreviewData.mediaHistoryMessages)
    }
}
#endif
