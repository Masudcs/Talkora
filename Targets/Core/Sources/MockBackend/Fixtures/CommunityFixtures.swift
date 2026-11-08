import Foundation

/// Seed community linking an existing group (`c5`) and channel (`ch1`).
public enum CommunityFixtures {
    public static let seed: [CommunityDTO] = [
        CommunityDTO(
            id: "com1",
            title: "Talkora HQ",
            description: "Everything about building Talkora, in one place.",
            ownerId: "u1",
            memberIds: ["u1", "u6", "u7", "u8"],
            linkedItems: [
                CommunityLinkedItemDTO(itemId: "c5", kind: "group", title: "Design Team"),
                CommunityLinkedItemDTO(itemId: "ch1", kind: "channel", title: "Talkora Announcements"),
            ],
            createdAt: "2024-06-01T09:00:00Z"
        ),
    ]
}
