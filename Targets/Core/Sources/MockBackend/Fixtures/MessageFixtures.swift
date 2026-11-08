import Foundation

public enum MessageFixtures {
    /// Keyed by conversationId, oldest first — mirrors how a real paginated history endpoint
    /// would be walked backwards from `updatedAt`.
    public static let seed: [String: [MessageDTO]] = [
        "c1": [
            MessageDTO(id: "m1", conversationId: "c1", senderId: "u2", text: "Hey! Are we still on for tonight?", createdAt: "2024-09-20T18:20:00Z"),
            MessageDTO(id: "m2", conversationId: "c1", senderId: "u1", text: "Yep, 6pm works for me", createdAt: "2024-09-20T18:25:00Z", deliveryState: "read"),
            MessageDTO(id: "m3", conversationId: "c1", senderId: "u2", text: "See you at 6!", createdAt: "2024-09-20T18:32:00Z"),
            MessageDTO(
                id: "m14", conversationId: "c1", senderId: "u2", text: "Here's the spot",
                createdAt: "2024-09-20T18:33:00Z",
                attachment: MediaAttachmentDTO(id: "att1", kind: "image", fileName: "IMG_0142.jpg", sizeBytes: 920_000, quality: "compressed", url: "https://picsum.photos/seed/asset1/800")
            ),
        ],
        "c2": [
            MessageDTO(id: "m4", conversationId: "c2", senderId: "u1", text: "Can you send over the project files?", createdAt: "2024-09-20T14:55:00Z", deliveryState: "read"),
            MessageDTO(id: "m5", conversationId: "c2", senderId: "u3", text: "Sent the files over", createdAt: "2024-09-20T15:10:00Z"),
        ],
        "c3": [
            MessageDTO(id: "m6", conversationId: "c3", senderId: "u4", text: "Who's driving up on Friday?", createdAt: "2024-09-20T11:40:00Z"),
            MessageDTO(id: "m7", conversationId: "c3", senderId: "u2", text: "I can take 3 people", createdAt: "2024-09-20T11:52:00Z"),
            MessageDTO(id: "m8", conversationId: "c3", senderId: "u5", text: "I'll bring the tent", createdAt: "2024-09-20T12:05:00Z"),
            MessageDTO(id: "m13", conversationId: "c3", senderId: "u2", text: "@me can you bring extra chairs?", createdAt: "2024-09-20T12:08:00Z", replyToMessageId: "m8"),
        ],
        "c4": [
            MessageDTO(id: "m9", conversationId: "c4", senderId: "u4", text: "Loved the recommendation, thank you!", createdAt: "2024-09-19T21:40:00Z"),
            MessageDTO(id: "m10", conversationId: "c4", senderId: "u1", text: "Sounds good, talk soon", createdAt: "2024-09-19T21:47:00Z", deliveryState: "delivered"),
        ],
        "c5": [
            MessageDTO(id: "m11", conversationId: "c5", senderId: "u6", text: "Standup moved to 10am tomorrow", createdAt: "2024-09-19T09:58:00Z"),
            MessageDTO(id: "m12", conversationId: "c5", senderId: "u7", text: "Updated the mockups", createdAt: "2024-09-19T10:22:00Z"),
            MessageDTO(
                id: "m15", conversationId: "c5", senderId: "u7", text: "",
                createdAt: "2024-09-19T10:25:00Z",
                attachment: MediaAttachmentDTO(id: "att2", kind: "file", fileName: "Budget.xlsx", sizeBytes: 210_000, quality: "original", url: nil)
            ),
        ],
    ]
}
