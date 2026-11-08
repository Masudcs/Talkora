import Foundation

/// Global and in-chat search, over `APIClientProtocol` — behaves the same against the mock, stubbed and live backends.
public final class SearchRepository: ISearchRepository {
    private let api: APIClientProtocol

    public init(api: APIClientProtocol = APIClientProvider.shared.client) {
        self.api = api
    }

    public func globalSearch(query: String, filter: MessageSearchFilter) async throws -> GlobalSearchResults {
        let dto: GlobalSearchResultsDTO = try await api.request(SearchRoutes.global(text: query, filter: filter))
        return dto.toDomain()
    }

    public func searchMessages(conversationId: String, query: String, filter: MessageSearchFilter) async throws -> [Message] {
        let dtos: [MessageDTO] = try await api.request(
            SearchRoutes.messages(conversationId: conversationId, text: query, filter: filter)
        )
        return dtos.map { $0.toDomain() }
    }
}
