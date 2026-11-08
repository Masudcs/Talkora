import SwiftUI
import Core

public extension Destination {
    /// Notification settings, presented modally via `presentedScreen()` (from Profile); the screen has its own `NavigationStack` and Done button.
    final class NotificationSettings: BaseDestination {
        public override func getScreen(navController: NavController) -> AnyView {
            AnyView(NotificationSettingsScreen())
        }
    }
}
