import Foundation
import Observation
import Core
import Mock

@MainActor
@Observable
final class GlobalSearchViewModel {
    var query: String = "" {
        didSet { scheduleSearch() }
    }
    var mediaOnlyChip = false {
        didSet { scheduleSearch() }
    }
    private(set) var results: GlobalSearchResults = .empty
    private(set) var isSearching = false

    private let repository: ISearchRepository
    private let chatRepository: IConversationRepository
    @ObservationIgnored private var searchTask: Task<Void, Never>?
    @ObservationIgnored private var isPreview = false

    init(repository: ISearchRepository = SearchRepository(), chatRepository: IConversationRepository = ChatRepository()) {
        self.repository = repository
        self.chatRepository = chatRepository
    }

    /// Reuses the find-or-create endpoint so tapping a contact from search behaves exactly
    /// like starting a chat from Contacts.
    func directConversationId(with user: User) async -> String? {
        try? await chatRepository.findOrCreateDirectConversation(with: user.id).id
    }

    deinit {
        searchTask?.cancel()
    }

    var trimmedQuery: String {
        query.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func scheduleSearch() {
        guard !isPreview else { return }
        searchTask?.cancel()
        guard !trimmedQuery.isEmpty else {
            results = .empty
            isSearching = false
            return
        }
        isSearching = true
        searchTask = Task {
            try? await Task.sleep(nanoseconds: 200_000_000)
            guard !Task.isCancelled else { return }
            await performSearch()
        }
    }

    private func performSearch() async {
        var parsed = SearchQueryParser.parse(trimmedQuery)
        if mediaOnlyChip { parsed.hasMediaOnly = true }
        var filter = MessageSearchFilter(hasMediaOnly: parsed.hasMediaOnly, after: parsed.after, before: parsed.before)
        if let handle = parsed.fromHandle {
            filter.senderId = try? await resolveSenderId(forHandle: handle)
        }
        guard let found = try? await repository.globalSearch(query: parsed.text, filter: filter) else { return }
        guard !Task.isCancelled else { return }
        results = found
        isSearching = false
    }

    /// `from:` filters resolve a typed handle to a user id via the same global search
    /// endpoint's contact results, rather than a separate lookup endpoint.
    private func resolveSenderId(forHandle handle: String) async throws -> String? {
        let matches = try await repository.globalSearch(query: handle, filter: MessageSearchFilter())
        return matches.users.first { $0.handle.localizedCaseInsensitiveContains(handle) }?.id
    }
}

#if DEBUG
extension GlobalSearchViewModel {
    /// The screen renders no error state, so `.failed` shows the same "no results" state as `.empty`.
    convenience init(previewScenario scenario: PreviewScenario) {
        self.init()
        isPreview = true
        switch scenario {
        case .loaded:
            query = "spot"
            results = PreviewData.globalSearchResults
        case .loading:
            query = "spot"
            isSearching = true
        case .empty, .failed:
            query = "zzz"
            results = .empty
        }
    }
}
#endif
