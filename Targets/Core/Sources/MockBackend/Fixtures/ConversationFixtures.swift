import Foundation

/// Seed conversations; their ids are the keys used by `MessageFixtures`.
public enum ConversationFixtures {
    public static let seed: [ConversationDTO] = [
        ConversationDTO(
            id: "c1",
            kind: "direct",
            title: "Amara Chen",
            participantIds: ["u1", "u2"],
            lastMessagePreview: "📷 Photo: Here's the spot",
            updatedAt: "2024-09-20T18:33:00Z"
        ),
        ConversationDTO(
            id: "c2",
            kind: "direct",
            title: "Diego Fernández",
            participantIds: ["u1", "u3"],
            lastMessagePreview: "Sent the files over",
            updatedAt: "2024-09-20T15:10:00Z"
        ),
        ConversationDTO(
            id: "c3",
            kind: "group",
            title: "Weekend Trip 🏕️",
            participantIds: ["u1", "u2", "u4", "u5"],
            lastMessagePreview: "Amara Chen: @me can you bring extra chairs?",
            updatedAt: "2024-09-20T12:08:00Z",
            members: [
                GroupMemberDTO(userId: "u2", role: "owner"),
                GroupMemberDTO(userId: "u4", role: "admin"),
                GroupMemberDTO(userId: "u1", role: "member"),
                GroupMemberDTO(userId: "u5", role: "member"),
            ],
            groupDescription: "Planning our camping trip this weekend!"
        ),
        ConversationDTO(
            id: "c4",
            kind: "direct",
            title: "Priya Nair",
            participantIds: ["u1", "u4"],
            lastMessagePreview: "Sounds good, talk soon",
            updatedAt: "2024-09-19T21:47:00Z"
        ),
        ConversationDTO(
            id: "c5",
            kind: "group",
            title: "Design Team",
            participantIds: ["u1", "u6", "u7", "u8"],
            lastMessagePreview: "Sofia Rossi: 📄 Budget.xlsx",
            updatedAt: "2024-09-19T10:25:00Z",
            members: [
                GroupMemberDTO(userId: "u1", role: "owner"),
                GroupMemberDTO(userId: "u7", role: "admin"),
                GroupMemberDTO(userId: "u6", role: "member"),
                GroupMemberDTO(userId: "u8", role: "member"),
            ],
            groupDescription: "Design team standups & updates",
            pinnedMessageId: "m11"
        ),
    ]
}
