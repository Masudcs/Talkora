import Foundation

/// Stories, highlights, viewers and the close-friends list. `privacy` carries the raw value of `StoryPrivacy`.
public enum StoryRoutes: EndpointConvertible {
    case active
    case highlights(authorId: String)
    case create(
        backgroundColorHex: String?,
        mediaAssetId: String?,
        overlayText: String?,
        overlayEmoji: String?,
        privacy: String,
        notifyOnScreenshot: Bool
    )
    case markViewed(storyId: String)
    case viewers(storyId: String)
    case setHighlighted(storyId: String, isHighlighted: Bool)
    case delete(storyId: String)
    case closeFriends
    case setCloseFriends(userIds: [String])

    public var endpoint: Endpoint {
        switch self {
        case .active:
            return Endpoint(path: "/stories")
        case .highlights(let authorId):
            return Endpoint(path: "/stories/highlights/\(authorId)")
        case .create(let backgroundColorHex, let mediaAssetId, let overlayText, let overlayEmoji, let privacy, let notifyOnScreenshot):
            return Endpoint(path: "/stories", method: .post, body: CreateBody(
                privacy: privacy,
                notifyOnScreenshot: notifyOnScreenshot,
                backgroundColorHex: backgroundColorHex,
                mediaAssetId: mediaAssetId,
                overlayText: overlayText,
                overlayEmoji: overlayEmoji
            ))
        case .markViewed(let storyId):
            return Endpoint(path: "/stories/\(storyId)/view", method: .post)
        case .viewers(let storyId):
            return Endpoint(path: "/stories/\(storyId)/viewers")
        case .setHighlighted(let storyId, let isHighlighted):
            return Endpoint(path: "/stories/\(storyId)", method: .patch, body: HighlightBody(isHighlighted: isHighlighted))
        case .delete(let storyId):
            return Endpoint(path: "/stories/\(storyId)", method: .delete)
        case .closeFriends:
            return Endpoint(path: "/close-friends")
        case .setCloseFriends(let userIds):
            return Endpoint(path: "/close-friends", method: .put, body: CloseFriendsBody(userIds: userIds))
        }
    }
}

// MARK: - Request bodies

/// Encodable request bodies for these routes.
public extension StoryRoutes {
    struct CreateBody: Encodable, Sendable {
        public let privacy: String
        public let notifyOnScreenshot: Bool
        public let backgroundColorHex: String?
        public let mediaAssetId: String?
        public let overlayText: String?
        public let overlayEmoji: String?

        public init(privacy: String, notifyOnScreenshot: Bool, backgroundColorHex: String?, mediaAssetId: String?, overlayText: String?, overlayEmoji: String?) {
            self.privacy = privacy
            self.notifyOnScreenshot = notifyOnScreenshot
            self.backgroundColorHex = backgroundColorHex
            self.mediaAssetId = mediaAssetId
            self.overlayText = overlayText
            self.overlayEmoji = overlayEmoji
        }
    }
    struct HighlightBody: Encodable, Sendable { let isHighlighted: Bool }
    struct CloseFriendsBody: Encodable, Sendable { let userIds: [String] }
}
