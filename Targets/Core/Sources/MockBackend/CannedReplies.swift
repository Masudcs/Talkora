import Foundation

/// Canned auto-reply pool used by `MockAPIClient`'s simulate-reply endpoint to make a
/// 1:1 conversation feel alive without a real second participant.
public enum CannedReplies {
    private static let pool = [
        "Sounds good!",
        "Got it, thanks.",
        "Haha, true.",
        "Let me check and get back to you.",
        "On my way!",
        "That works for me.",
    ]

    public static func random() -> String {
        pool.randomElement() ?? "👍"
    }
}
