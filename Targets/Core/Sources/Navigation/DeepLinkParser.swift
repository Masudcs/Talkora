import Foundation

/// Parses `talkora://conversation/<id>` links into an `AppRoute`. Not wired up yet: nothing in
/// the app calls it, so no entry point (`onOpenURL`, a notification tap) opens these links today.
public enum DeepLinkParser {
    public static func route(for url: URL) -> AppRoute? {
        guard url.scheme == "talkora", url.host == "conversation" else { return nil }
        let id = url.lastPathComponent
        guard !id.isEmpty else { return nil }
        return .conversation(id: id)
    }
}
