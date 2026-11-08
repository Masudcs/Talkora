import Foundation

/// Seed channels. `u1` administers `ch1` and follows it, `ch2` is owned by someone else.
public enum ChannelFixtures {
    public static let seed: [ChannelDTO] = [
        ChannelDTO(
            id: "ch1",
            title: "Talkora Announcements",
            description: "Official product updates and release notes.",
            ownerId: "u7",
            adminIds: ["u1"],
            followerIds: ["u1", "u2", "u3", "u4"],
            createdAt: "2024-06-01T09:00:00Z"
        ),
        ChannelDTO(
            id: "ch2",
            title: "Daily Tech Digest",
            description: "One link a day, curated by the team.",
            ownerId: "u5",
            followerIds: ["u2", "u6"],
            createdAt: "2024-07-12T09:00:00Z"
        ),
    ]
}
