import Foundation

/// Seed users: `u1` is the signed-in demo user, `u2`-`u8` are people, `bot1` and `bot2` back the bots in `BotFixtures`.
public enum UserFixtures {
    /// Seed users reused across every module's fixtures. Keep referential integrity in mind:
    /// any `senderId`/`participantId` used elsewhere must exist here.
    public static let seed: [UserDTO] = [
        UserDTO(id: "u1", displayName: "You", handle: "@me", avatarURL: "https://picsum.photos/seed/u1/200", status: "online", createdAt: "2024-01-10T09:00:00Z", bio: "Building Talkora 🚀"),
        UserDTO(id: "u2", displayName: "Amara Chen", handle: "@amara", avatarURL: "https://picsum.photos/seed/u2/200", status: "online", createdAt: "2024-01-15T09:00:00Z"),
        UserDTO(id: "u3", displayName: "Diego Fernández", handle: "@diego", avatarURL: "https://picsum.photos/seed/u3/200", status: "offline", createdAt: "2024-02-02T09:00:00Z"),
        UserDTO(id: "u4", displayName: "Priya Nair", handle: "@priya", avatarURL: "https://picsum.photos/seed/u4/200", status: "away", createdAt: "2024-02-10T09:00:00Z"),
        UserDTO(id: "u5", displayName: "Kwame Boateng", handle: "@kwame", avatarURL: "https://picsum.photos/seed/u5/200", status: "online", createdAt: "2024-02-18T09:00:00Z"),
        UserDTO(id: "u6", displayName: "Yuki Tanaka", handle: "@yuki", avatarURL: "https://picsum.photos/seed/u6/200", status: "offline", createdAt: "2024-03-01T09:00:00Z"),
        UserDTO(id: "u7", displayName: "Sofia Rossi", handle: "@sofia", avatarURL: "https://picsum.photos/seed/u7/200", status: "online", createdAt: "2024-03-05T09:00:00Z"),
        UserDTO(id: "u8", displayName: "Liam O'Connor", handle: "@liam", avatarURL: "https://picsum.photos/seed/u8/200", status: "offline", createdAt: "2024-03-09T09:00:00Z"),
        UserDTO(id: "bot1", displayName: "Reminder Bot", handle: "@reminderbot", avatarURL: "https://picsum.photos/seed/bot1/200", status: "online", createdAt: "2024-01-01T09:00:00Z", bio: "Tell me what to remember; I'll ping you back.", isBot: true),
        UserDTO(id: "bot2", displayName: "Fact Bot", handle: "@factbot", avatarURL: "https://picsum.photos/seed/bot2/200", status: "online", createdAt: "2024-01-01T09:00:00Z", bio: "Say anything, get a random fact back.", isBot: true),
    ]

    /// Convenience: the fixture representing the signed-in user for this mock session.
    public static let currentUser = seed[0]
}
