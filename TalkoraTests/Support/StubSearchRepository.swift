@testable import Talkora
import Foundation
@testable import Core

final class StubSearchRepository: ISearchRepository {
    var globalSearchResult: Result<GlobalSearchResults, Error> = .failure(StubFailure.notConfigured)
    var searchMessagesResult: Result<[Message], Error> = .success([])
    private(set) var globalSearchCallCount = 0
    private(set) var lastGlobalQuery: String?

    func globalSearch(query: String, filter: MessageSearchFilter) async throws -> GlobalSearchResults {
        globalSearchCallCount += 1
        lastGlobalQuery = query
        return try globalSearchResult.get()
    }

    func searchMessages(conversationId: String, query: String, filter: MessageSearchFilter) async throws -> [Message] {
        try searchMessagesResult.get()
    }
}
