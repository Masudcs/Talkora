import Foundation

/// Wire-format channel post. `viewerIds` is reduced to a view count by the mapper.
public struct ChannelPostDTO: Codable, Sendable, Hashable {
    public let id: String
    public let channelId: String
    public let authorId: String
    public let text: String
    public let createdAt: String
    public let viewerIds: [String]

    public init(id: String, channelId: String, authorId: String, text: String, createdAt: String, viewerIds: [String] = []) {
        self.id = id
        self.channelId = channelId
        self.authorId = authorId
        self.text = text
        self.createdAt = createdAt
        self.viewerIds = viewerIds
    }

    public func with(viewerIds: [String]? = nil) -> ChannelPostDTO {
        ChannelPostDTO(
            id: id,
            channelId: channelId,
            authorId: authorId,
            text: text,
            createdAt: createdAt,
            viewerIds: viewerIds ?? self.viewerIds
        )
    }
}
