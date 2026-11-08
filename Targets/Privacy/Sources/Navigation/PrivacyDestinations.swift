import SwiftUI
import Core

public extension Destination {
    /// The Privacy & Security hub. Public because the Settings tab (Profile module) presents it as a sheet.
    final class Privacy: BaseDestination {
        public override func getScreen(navController: NavController) -> AnyView {
            AnyView(PrivacyScreen())
        }
    }
}
