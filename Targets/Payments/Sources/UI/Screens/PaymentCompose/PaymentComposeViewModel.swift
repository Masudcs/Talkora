import Foundation
import Observation
import Core
import Mock

/// Drives the send/request money form. `mode` decides which repository call `submit()` makes.
@MainActor
@Observable
final class PaymentComposeViewModel {
    let mode: PaymentComposeMode
    let counterpart: User
    let conversationId: String
    /// Raw field text; parsed on demand by `amount`.
    var amountText: String = ""
    var note: String = ""
    private(set) var isSubmitting = false
    private(set) var error: AppError?
    /// Set once the transfer went through; the screen watches it to call `onCompleted` and dismiss.
    private(set) var didSucceed = false

    private let repository: IPaymentTransferRepository

    init(mode: PaymentComposeMode, counterpart: User, conversationId: String, repository: IPaymentTransferRepository = PaymentRepository()) {
        self.mode = mode
        self.counterpart = counterpart
        self.conversationId = conversationId
        self.repository = repository
    }

    /// `nil` when the text is not a plain number (`Double(_:)` is not locale-aware, so a decimal comma fails).
    var amount: Double? {
        Double(amountText)
    }

    /// Needs a positive amount and no request already in flight.
    var canSubmit: Bool {
        (amount ?? 0) > 0 && !isSubmitting
    }

    /// Sends or requests money. A blank note is sent as `nil`. Failures land in `error` (e.g. unverified KYC or insufficient balance, which the backend rejects); `didSucceed` stays false.
    func submit() async {
        guard let amount, amount > 0 else { return }
        isSubmitting = true
        defer { isSubmitting = false }
        let trimmedNote = note.trimmingCharacters(in: .whitespacesAndNewlines)
        do {
            switch mode {
            case .send:
                _ = try await repository.sendMoney(to: counterpart.id, amount: amount, note: trimmedNote.isEmpty ? nil : trimmedNote, conversationId: conversationId)
            case .request:
                _ = try await repository.requestMoney(from: counterpart.id, amount: amount, note: trimmedNote.isEmpty ? nil : trimmedNote, conversationId: conversationId)
            }
            didSucceed = true
        } catch {
            self.error = error.asAppError
        }
    }
}

#if DEBUG
extension PaymentComposeViewModel {
    convenience init(previewMode mode: PaymentComposeMode, scenario: FormPreviewScenario) {
        let counterpart = PreviewData.users.first { $0.id != PreviewData.currentUser.id } ?? PreviewData.currentUser
        self.init(mode: mode, counterpart: counterpart, conversationId: PreviewData.directConversation.id)
        switch scenario {
        case .empty: break
        case .invalid: amountText = "0"
        case .filled: amountText = "25"; note = "Lunch"
        case .submitting: amountText = "25"; note = "Lunch"; isSubmitting = true
        case .failed: amountText = "25"; note = "Lunch"; error = PreviewData.error
        }
    }
}
#endif
