import SwiftUI
import Core

public extension Destination {
    /// Per-conversation "Media & Files" grid, keyed by conversation id.
    final class MediaHistory: BaseDestination {
        public let conversationId: String
        public init(conversationId: String) { self.conversationId = conversationId }
        public override var parameterKey: String { conversationId }
        public override func getScreen(navController: NavController) -> AnyView {
            AnyView(MediaHistoryScreen(conversationId: conversationId))
        }
    }

    /// Asset picker -> compose flow, meant to be presented as a sheet (the screen has its own `NavigationStack`). `onSent` receives the sent message and the sheet then dismisses itself.
    final class MediaPicker: BaseDestination {
        public let conversationId: String
        public let onSent: (Message) -> Void
        public init(conversationId: String, onSent: @escaping (Message) -> Void) {
            self.conversationId = conversationId
            self.onSent = onSent
        }
        public override var parameterKey: String { conversationId }
        public override func getScreen(navController: NavController) -> AnyView {
            AnyView(MediaPickerScreen(conversationId: conversationId, onSent: onSent))
        }
    }
}
