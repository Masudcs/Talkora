import Foundation

/// Wire-format story. `privacy` is a `StoryPrivacy` raw value; timestamps are ISO 8601 strings, and `expiresAt` is ignored for highlighted stories.
public struct StoryDTO: Codable, Sendable, Hashable {
    public let id: String
    public let authorId: String
    public let createdAt: String
    public let expiresAt: String
    public let backgroundColorHex: String?
    public let mediaURL: String?
    public let overlayText: String?
    public let overlayEmoji: String?
    public let privacy: String
    public let notifyOnScreenshot: Bool
    public let viewerIds: [String]
    public let isHighlighted: Bool

    public init(
        id: String,
        authorId: String,
        createdAt: String,
        expiresAt: String,
        backgroundColorHex: String?,
        mediaURL: String?,
        overlayText: String?,
        overlayEmoji: String?,
        privacy: String,
        notifyOnScreenshot: Bool,
        viewerIds: [String] = [],
        isHighlighted: Bool = false
    ) {
        self.id = id
        self.authorId = authorId
        self.createdAt = createdAt
        self.expiresAt = expiresAt
        self.backgroundColorHex = backgroundColorHex
        self.mediaURL = mediaURL
        self.overlayText = overlayText
        self.overlayEmoji = overlayEmoji
        self.privacy = privacy
        self.notifyOnScreenshot = notifyOnScreenshot
        self.viewerIds = viewerIds
        self.isHighlighted = isHighlighted
    }

    public func with(viewerIds: [String]? = nil, isHighlighted: Bool? = nil) -> StoryDTO {
        StoryDTO(
            id: id,
            authorId: authorId,
            createdAt: createdAt,
            expiresAt: expiresAt,
            backgroundColorHex: backgroundColorHex,
            mediaURL: mediaURL,
            overlayText: overlayText,
            overlayEmoji: overlayEmoji,
            privacy: privacy,
            notifyOnScreenshot: notifyOnScreenshot,
            viewerIds: viewerIds ?? self.viewerIds,
            isHighlighted: isHighlighted ?? self.isHighlighted
        )
    }
}
