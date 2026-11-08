import SwiftUI
import Core

/// Destinations pushed from the Settings tab.
extension Destination {
    /// Storage breakdown and data export.
    final class DataUsage: BaseDestination {
        override func getScreen(navController: NavController) -> AnyView {
            AnyView(DataUsageScreen())
        }
    }
}
