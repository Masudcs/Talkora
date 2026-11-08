import Foundation

/// Seed channel posts, keyed by channel id.
public enum ChannelPostFixtures {
    public static let seed: [String: [ChannelPostDTO]] = [
        "ch1": [
            ChannelPostDTO(
                id: "chp1",
                channelId: "ch1",
                authorId: "u7",
                text: "Talkora 1.0 is live! Thanks for being early testers 🎉",
                createdAt: "2024-09-15T09:00:00Z",
                viewerIds: ["u1", "u2", "u3"]
            ),
            ChannelPostDTO(
                id: "chp2",
                channelId: "ch1",
                authorId: "u1",
                text: "Heads up: scheduled maintenance this weekend, expect brief slowdowns.",
                createdAt: "2024-09-19T14:00:00Z",
                viewerIds: ["u2"]
            ),
        ],
        "ch2": [
            ChannelPostDTO(
                id: "chp3",
                channelId: "ch2",
                authorId: "u5",
                text: "Today's read: why local-first apps are having a moment.",
                createdAt: "2024-09-20T08:00:00Z",
                viewerIds: ["u2", "u6"]
            ),
        ],
    ]
}
