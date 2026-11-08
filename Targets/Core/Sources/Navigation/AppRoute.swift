import Foundation

/// Cross-feature navigation target, intended for jumps that cross a feature boundary (a search
/// result opening a chat, a notification tap opening a conversation). Not used yet: features
/// currently navigate through their own `Destination` subclasses and `NavController`, and no
/// view resolves an `AppRoute`.
public enum AppRoute: Hashable, Sendable {
    case conversation(id: String)
}
