import SwiftUI
import Core

/// Modal form for sending or requesting money from `counterpart`. Wraps its content in its own `NavigationStack` for the title and Cancel/confirm toolbar.
struct PaymentComposeScreen: View {
    /// Called after a successful transfer, before the screen dismisses itself.
    let onCompleted: () -> Void
    @State private var viewModel: PaymentComposeViewModel
    @Environment(\.dismiss) private var dismiss

    /// `viewModel` is only for previews and tests; production callers let the screen build its own.
    init(mode: PaymentComposeMode, counterpart: User, conversationId: String, onCompleted: @escaping () -> Void, viewModel: PaymentComposeViewModel? = nil) {
        self.onCompleted = onCompleted
        _viewModel = State(wrappedValue: viewModel ?? PaymentComposeViewModel(
            mode: mode,
            counterpart: counterpart,
            conversationId: conversationId
        ))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Text(viewModel.mode == .send ? "To" : "From")
                        Spacer()
                        Text(viewModel.counterpart.displayName).foregroundStyle(Color.secondary)
                    }
                    TextField("Amount", text: $viewModel.amountText)
                        .keyboardType(.decimalPad)
                    TextField("Add a note (optional)", text: $viewModel.note)
                }

                if let error = viewModel.error {
                    Section {
                        Text(error.userMessage).foregroundStyle(Color.red)
                    }
                }
            }
            .navigationTitle(viewModel.mode.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    if viewModel.isSubmitting {
                        ProgressView()
                    } else {
                        Button(viewModel.mode.actionLabel) {
                            Task {
                                await viewModel.submit()
                                if viewModel.didSucceed {
                                    onCompleted()
                                    dismiss()
                                }
                            }
                        }
                        .disabled(!viewModel.canSubmit)
                    }
                }
            }
        }
    }
}

#if DEBUG
@MainActor private func composePreview(_ mode: PaymentComposeMode, _ scenario: FormPreviewScenario) -> some View {
    let vm = PaymentComposeViewModel(previewMode: mode, scenario: scenario)
    return PaymentComposeScreen(mode: mode, counterpart: vm.counterpart, conversationId: vm.conversationId, onCompleted: {}, viewModel: vm)
}

#Preview("Send - Empty") { composePreview(.send, .empty) }
#Preview("Send - Filled") { composePreview(.send, .filled) }
#Preview("Send - Invalid") { composePreview(.send, .invalid) }
#Preview("Send - Submitting") { composePreview(.send, .submitting) }
#Preview("Send - Error") { composePreview(.send, .failed) }
#Preview("Request - Empty") { composePreview(.request, .empty) }
#Preview("Request - Filled") { composePreview(.request, .filled) }
#endif
