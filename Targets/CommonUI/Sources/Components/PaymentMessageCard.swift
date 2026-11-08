import SwiftUI
import Core

/// Rendered by `MessageBubbleView` in place of the normal text/media bubble when a
/// message has a `paymentTransactionId` — visually distinct from a regular chat bubble.
public struct PaymentMessageCard: View {
    public let text: String
    /// Without it the card shows only the text and no Pay / Decline buttons.
    public let payment: PaymentTransaction?
    public let currentUserId: String
    /// Called with `true` to accept (pay) or `false` to decline.
    public let onRespond: (Bool) -> Void

    /// Only the person asked to pay (`toUserId`) sees the Pay / Decline buttons, and only while the request is still pending.
    private var isActionablePendingRequest: Bool {
        guard let payment else { return false }
        return payment.status == .pendingAcceptance && payment.toUserId == currentUserId
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "dollarsign.circle.fill")
                    .foregroundStyle(Color.green)
                Text(text)
                    .font(Font.body)
                    .foregroundStyle(Color.primary)
            }
            if isActionablePendingRequest {
                HStack(spacing: 8) {
                    Button("Decline") { onRespond(false) }
                        .buttonStyle(.bordered)
                    Button("Pay") { onRespond(true) }
                        .buttonStyle(.borderedProminent)
                }
                .font(.caption)
            }
        }
        .padding(16)
        .background(Color.green.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(Color.green.opacity(0.3), lineWidth: 1))
    }

    public init(text: String, payment: PaymentTransaction?, currentUserId: String, onRespond: @escaping (Bool) -> Void) {
        self.text = text
        self.payment = payment
        self.currentUserId = currentUserId
        self.onRespond = onRespond
    }
}
