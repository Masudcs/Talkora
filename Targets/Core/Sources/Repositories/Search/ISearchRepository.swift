import Foundation

public protocol ISearchRepository: Sendable {
    /// Cross-chat: matching conversation titles, messages (media/file-aware, not just
    /// text), and contacts, in one call — mirrors a real global search endpoint.
    func globalSearch(query: String, filter: MessageSearchFilter) async throws -> GlobalSearchResults
    /// Searches a single conversation.
    func searchMessages(conversationId: String, query: String, filter: MessageSearchFilter) async throws -> [Message]
}
