import Foundation

/// Unknown privacy values fall back to `.everyone`; a malformed `mediaURL` becomes `nil`.
public extension StoryDTO {
    func toDomain() -> Story {
        Story(
            id: id,
            authorId: authorId,
            createdAt: ISO8601.date(from: createdAt),
            expiresAt: ISO8601.date(from: expiresAt),
            backgroundColorHex: backgroundColorHex,
            mediaURL: mediaURL.flatMap(URL.init(string:)),
            overlayText: overlayText,
            overlayEmoji: overlayEmoji,
            privacy: StoryPrivacy(rawValue: privacy) ?? .everyone,
            notifyOnScreenshot: notifyOnScreenshot,
            viewerIds: viewerIds,
            isHighlighted: isHighlighted
        )
    }
}
