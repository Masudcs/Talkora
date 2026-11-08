import SwiftUI
import Core

public extension Destination {
    /// Pushes the call screen. `parameterKey` is the request's UUID so two calls to the same person are distinct stack entries.
    final class Call: BaseDestination {
        public let request: ActiveCallRequest
        public init(request: ActiveCallRequest) { self.request = request }
        public override var parameterKey: String { request.id.uuidString }
        public override func getScreen(navController: NavController) -> AnyView {
            AnyView(CallScreen(request: request))
        }
    }
}
