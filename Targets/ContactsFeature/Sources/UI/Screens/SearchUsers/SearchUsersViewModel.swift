import Foundation
import Observation
import Core
import Mock

/// Search-and-request state. Failures of the search itself are swallowed as empty results; only request failures surface via `requestError`.
@MainActor
@Observable
final class SearchUsersViewModel {
    @ObservationIgnored private var isPreview = false
    var query: String = ""
    private(set) var results: [User] = []
    private(set) var isSearching = false
    /// Users already requested this session, so their row shows "Sent" instead of "Add".
    private(set) var sentRequestUserIds: Set<String> = []
    private(set) var requestError: AppError?

    private let contactRepository: IContactRepository

    init(contactRepository: IContactRepository = ContactRepository()) {
        self.contactRepository = contactRepository
    }

    /// A blank (whitespace-only) query clears results without calling the repository.
    func search() async {
        guard !isPreview else { return }
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else {
            results = []
            return
        }
        isSearching = true
        defer { isSearching = false }
        results = (try? await contactRepository.searchUsers(query: query)) ?? []
    }

    func sendRequest(to user: User) async {
        do {
            _ = try await contactRepository.sendContactRequest(to: user.id)
            sentRequestUserIds.insert(user.id)
        } catch {
            requestError = error.asAppError
        }
    }
}

#if DEBUG
extension SearchUsersViewModel {
    /// `.loaded` shows results (one already requested); `.empty` an untouched search;
    /// `.failed` results plus a request error. `.loading` shows the results mid-search.
    convenience init(previewScenario scenario: PreviewScenario) {
        self.init()
        isPreview = true
        let others = PreviewData.users.filter { $0.id != PreviewData.currentUser.id }
        switch scenario {
        case .empty:
            break
        case .loaded, .loading, .failed:
            query = "a"
            results = others
            sentRequestUserIds = Set(others.prefix(1).map(\.id))
            isSearching = scenario == .loading
            requestError = scenario == .failed ? PreviewData.error : nil
        }
    }
}
#endif
