#if DEBUG
import Foundation
import Core

public extension PreviewData {
    /// Everyone except the current user, for member pickers.
    static var otherUsers: [User] {
        users.filter { $0.id != currentUser.id }
    }
}
#endif
