import SwiftUI
import Core

/// Full-screen error placeholder for `LoadableState.failed`. The "Try Again" button only appears when the error is retryable and an `onRetry` closure is given.
public struct ErrorStateView: View {
    private let message: String
    private let isRetryable: Bool
    private let onRetry: (() -> Void)?

    public init(message: String, isRetryable: Bool = true, onRetry: (() -> Void)? = nil) {
        self.message = message
        self.isRetryable = isRetryable
        self.onRetry = onRetry
    }

    public var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 36))
                .foregroundStyle(Color.red)
            Text(message)
                .font(Font.body)
                .foregroundStyle(Color.primary)
                .multilineTextAlignment(.center)
            if isRetryable, let onRetry {
                Button("Try Again", action: onRetry)
                    .buttonStyle(.borderedProminent)
                    .tint(Color.accentColor)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}

#Preview {
    ErrorStateView(message: "You appear to be offline.", onRetry: {})
}
