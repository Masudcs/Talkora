import Foundation

/// Generic cursor-paginated page of results, returned by any endpoint that supports paging
/// (conversation lists, message history, search results, ...).
public struct Page<T>: Sendable where T: Sendable {
    public let items: [T]
    public let nextCursor: String?
    public let hasMore: Bool

    public init(items: [T], nextCursor: String?, hasMore: Bool) {
        self.items = items
        self.nextCursor = nextCursor
        self.hasMore = hasMore
    }
}
