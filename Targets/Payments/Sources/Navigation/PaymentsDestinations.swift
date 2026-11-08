import SwiftUI
import Core

public extension Destination {
    /// Pushes the wallet: balance, top-up, KYC and transaction history.
    final class Wallet: BaseDestination {
        public override func getScreen(navController: NavController) -> AnyView {
            AnyView(WalletScreen())
        }
    }

    /// Opens the send/request money form for one counterpart, normally from a conversation. `onCompleted` fires only after the transfer succeeded, so the caller can refresh.
    final class PaymentCompose: BaseDestination {
        public let mode: PaymentComposeMode
        public let counterpart: User
        public let conversationId: String
        public let onCompleted: () -> Void
        public init(mode: PaymentComposeMode, counterpart: User, conversationId: String, onCompleted: @escaping () -> Void) {
            self.mode = mode
            self.counterpart = counterpart
            self.conversationId = conversationId
            self.onCompleted = onCompleted
        }
        /// Identifies the route by conversation and counterpart; `mode` is not part of the key.
        public override var parameterKey: String { "\(conversationId)-\(counterpart.id)" }
        public override func getScreen(navController: NavController) -> AnyView {
            AnyView(PaymentComposeScreen(
                mode: mode,
                counterpart: counterpart,
                conversationId: conversationId,
                onCompleted: onCompleted
            ))
        }
    }
}
