import Foundation

/// Per-conversation background, applied only to the thread view. Kept to a fixed palette
/// of gradients (no real image upload) since this is a demo/mock backend — mirrors
/// `NotificationSound`'s "few, always-functional options" approach.
public enum ChatWallpaper: String, Sendable, CaseIterable {
    case `default`
    case ocean
    case sunset
    case forest
    case midnight
}
