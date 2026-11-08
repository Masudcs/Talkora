import Foundation

/// Unlike other fixtures, story timestamps must be computed relative to launch time —
/// a hardcoded historical date would already be "expired" by the time the app runs.
public enum StoryFixtures {
    public static func seed(now: Date = Date(), expiryDuration: TimeInterval) -> [StoryDTO] {
        [
            StoryDTO(
                id: "story1",
                authorId: "u2",
                createdAt: ISO8601Formatting.string(from: now.addingTimeInterval(-20)),
                expiresAt: ISO8601Formatting.string(from: now.addingTimeInterval(-20 + expiryDuration)),
                backgroundColorHex: nil,
                mediaURL: "https://picsum.photos/seed/story1/800",
                overlayText: "Beautiful sunset today 🌅",
                overlayEmoji: nil,
                privacy: "everyone",
                notifyOnScreenshot: false
            ),
            StoryDTO(
                id: "story2",
                authorId: "u4",
                createdAt: ISO8601Formatting.string(from: now.addingTimeInterval(-50)),
                expiresAt: ISO8601Formatting.string(from: now.addingTimeInterval(-50 + expiryDuration)),
                backgroundColorHex: "#5856D6",
                mediaURL: nil,
                overlayText: "Coffee time",
                overlayEmoji: "☕️",
                privacy: "everyone",
                notifyOnScreenshot: false,
                viewerIds: ["u1"]
            ),
            StoryDTO(
                id: "story3",
                authorId: "u1",
                createdAt: ISO8601Formatting.string(from: now.addingTimeInterval(-90_000)),
                expiresAt: ISO8601Formatting.string(from: now.addingTimeInterval(-90_000 + expiryDuration)),
                backgroundColorHex: "#FF9500",
                mediaURL: nil,
                overlayText: "Throwback",
                overlayEmoji: "✨",
                privacy: "everyone",
                notifyOnScreenshot: false,
                viewerIds: ["u2", "u4"],
                isHighlighted: true
            ),
        ]
    }
}
