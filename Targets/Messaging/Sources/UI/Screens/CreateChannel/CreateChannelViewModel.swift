import Foundation
import Observation
import Core

@MainActor
@Observable
final class CreateChannelViewModel {
    var title = ""
    var description = ""
    private(set) var isSubmitting = false

    private let onCreate: (String, String?) async -> Void

    init(onCreate: @escaping (String, String?) async -> Void) {
        self.onCreate = onCreate
    }

    var canSubmit: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func submit() async {
        guard canSubmit else { return }
        isSubmitting = true
        defer { isSubmitting = false }
        await onCreate(title, description.isEmpty ? nil : description)
    }
}

#if DEBUG
extension CreateChannelViewModel {
    /// The form has no error state, so `.failed` falls back to the filled form.
    convenience init(previewScenario scenario: FormPreviewScenario) {
        self.init(onCreate: { _, _ in })
        switch scenario {
        case .empty: break
        case .invalid: title = "   "; description = "A description without a name"
        case .filled, .failed: title = "Design Team"; description = "Updates and announcements"
        case .submitting: title = "Design Team"; description = "Updates and announcements"; isSubmitting = true
        }
    }
}
#endif
