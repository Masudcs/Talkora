import Foundation

/// Uncommon (Telegram): per-conversation notification sound. Kept to two real, always-
/// functional options since custom tones would need bundled audio assets — `.silent`
/// genuinely suppresses both sound and the system's sound-tied vibration, distinct from
/// a full mute (the banner/summary still appears, just silently).
public enum NotificationSound: String, Sendable, CaseIterable {
    case standard
    case silent
}
