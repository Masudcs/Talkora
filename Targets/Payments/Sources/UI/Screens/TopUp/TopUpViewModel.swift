import Foundation
import Observation
import Core

/// Form state for adding demo funds. It does not call the repository itself: the submit work is injected so `WalletViewModel` owns the top-up and the refresh that follows.
@MainActor
@Observable
final class TopUpViewModel {
    var amountText = ""
    private(set) var isSubmitting = false

    private let onSubmit: (Double) async -> Void

    init(onSubmit: @escaping (Double) async -> Void) {
        self.onSubmit = onSubmit
    }

    var amount: Double? {
        Double(amountText)
    }

    /// True for any positive parseable amount. Unlike the compose form it does not check `isSubmitting`; the sheet swaps the button for a spinner instead.
    var canSubmit: Bool {
        (amount ?? 0) > 0
    }

    /// Hands the amount to the injected handler and holds `isSubmitting` until it returns. Errors are reported by the handler's owner, not here.
    func submit() async {
        guard let amount, amount > 0 else { return }
        isSubmitting = true
        defer { isSubmitting = false }
        await onSubmit(amount)
    }
}

#if DEBUG
extension TopUpViewModel {
    /// The form has no error state, so `.failed` falls back to the filled form.
    convenience init(previewScenario scenario: FormPreviewScenario) {
        self.init(onSubmit: { _ in })
        switch scenario {
        case .empty: break
        case .invalid: amountText = "abc"
        case .filled, .failed: amountText = "50"
        case .submitting: amountText = "50"; isSubmitting = true
        }
    }
}
#endif
