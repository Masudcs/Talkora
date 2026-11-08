import Foundation
import Observation
import Core

/// Form state for the simulated identity check. Submission is injected (`onSubmit(fullName, country)`) so the wallet screen owns the call and the reload.
@MainActor
@Observable
final class KYCViewModel {
    var fullName = ""
    var country = ""
    private(set) var isSubmitting = false

    private let onSubmit: (String, String) async -> Void

    init(onSubmit: @escaping (String, String) async -> Void) {
        self.onSubmit = onSubmit
    }

    /// Both fields must be non-blank after trimming.
    var canSubmit: Bool {
        !fullName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !country.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// Passes the untrimmed values to the handler; the handler is responsible for any normalising.
    func submit() async {
        guard canSubmit else { return }
        isSubmitting = true
        defer { isSubmitting = false }
        await onSubmit(fullName, country)
    }
}

#if DEBUG
extension KYCViewModel {
    /// The form has no error state, so `.failed` falls back to the filled form.
    convenience init(previewScenario scenario: FormPreviewScenario) {
        self.init(onSubmit: { _, _ in })
        switch scenario {
        case .empty: break
        case .invalid: fullName = "Amina Rahman"; country = "  "
        case .filled, .failed: fullName = "Amina Rahman"; country = "Bangladesh"
        case .submitting: fullName = "Amina Rahman"; country = "Bangladesh"; isSubmitting = true
        }
    }
}
#endif
