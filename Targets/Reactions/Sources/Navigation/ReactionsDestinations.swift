import SwiftUI
import Core

public extension Destination {
    /// Reaction statistics for one group conversation, keyed by conversation id.
    final class ReactionAnalytics: BaseDestination {
        public let conversationId: String
        public init(conversationId: String) { self.conversationId = conversationId }
        public override var parameterKey: String { conversationId }
        public override func getScreen(navController: NavController) -> AnyView {
            AnyView(ReactionAnalyticsScreen(conversationId: conversationId))
        }
    }
}
