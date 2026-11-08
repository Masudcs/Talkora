import Foundation

/// Who can see a story: everyone, only the author's close friends, or only the author.
public enum StoryPrivacy: String, Sendable {
    case everyone
    case closeFriends
    case onlyMe
}

/// A 24-hour status post (shorter in Dev/Staging, see `AppEnvironment.storyExpiryDuration`).
public struct Story: Identifiable, Hashable, Sendable {
    public let id: String
    public let authorId: String
    public let createdAt: Date
    public let expiresAt: Date
    public let backgroundColorHex: String?
    public let mediaURL: URL?
    public let overlayText: String?
    public let overlayEmoji: String?
    public let privacy: StoryPrivacy
    /// Improve: explicit, per-story control shown at post time rather than a buried,
    /// app-wide setting — even though this mock can't detect real screenshots.
    public let notifyOnScreenshot: Bool
    public let viewerIds: [String]
    /// Uncommon (Instagram): saved to a permanent Highlight — never expires.
    public let isHighlighted: Bool

    public var isExpired: Bool {
        !isHighlighted && Date() >= expiresAt
    }

    public init(id: String, authorId: String, createdAt: Date, expiresAt: Date, backgroundColorHex: String?, mediaURL: URL?, overlayText: String?, overlayEmoji: String?, privacy: StoryPrivacy, notifyOnScreenshot: Bool, viewerIds: [String], isHighlighted: Bool) {
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
}
