import Foundation
import Observation
import Core
import Mock

@MainActor
@Observable
final class InChatSearchViewModel {
    let conversationId: String
    var query: String = "" {
        didSet { scheduleSearch() }
    }
    var mediaOnly = false {
        didSet { scheduleSearch() }
    }
    private(set) var results: [Message] = []
    private(set) var isSearching = false

    private let repository: ISearchRepository
    @ObservationIgnored private var searchTask: Task<Void, Never>?
    @ObservationIgnored private var isPreview = false

    init(conversationId: String, repository: ISearchRepository = SearchRepository()) {
        self.conversationId = conversationId
        self.repository = repository
    }

    deinit {
        searchTask?.cancel()
    }

    private func scheduleSearch() {
        guard !isPreview else { return }
        searchTask?.cancel()
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty || mediaOnly else {
            results = []
            isSearching = false
            return
        }
        isSearching = true
        searchTask = Task {
            try? await Task.sleep(nanoseconds: 200_000_000)
            guard !Task.isCancelled else { return }
            let parsed = SearchQueryParser.parse(trimmed)
            let filter = MessageSearchFilter(hasMediaOnly: mediaOnly || parsed.hasMediaOnly, after: parsed.after, before: parsed.before)
            guard let found = try? await repository.searchMessages(conversationId: conversationId, query: parsed.text, filter: filter) else { return }
            guard !Task.isCancelled else { return }
            results = found
            isSearching = false
        }
    }
}

#if DEBUG
extension InChatSearchViewModel {
    /// The screen renders no error state, so `.failed` shows the same "no matches" state as `.empty`.
    convenience init(previewScenario scenario: PreviewScenario) {
        self.init(conversationId: PreviewData.directConversation.id)
        isPreview = true
        switch scenario {
        case .loaded:
            query = "spot"
            results = PreviewData.searchMessages
        case .loading:
            query = "spot"
            isSearching = true
        case .empty, .failed:
            query = "zzz"
            results = []
        }
    }
}
#endif
