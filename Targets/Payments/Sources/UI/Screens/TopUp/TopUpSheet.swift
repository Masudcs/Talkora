import SwiftUI
import Core

/// Sheet for crediting the mock wallet. Dismisses after the handler returns, whether or not the top-up succeeded; a failure is shown on the wallet screen via `actionError`.
struct TopUpSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: TopUpViewModel

    init(onSubmit: @escaping (Double) async -> Void, viewModel: TopUpViewModel? = nil) {
        _viewModel = State(wrappedValue: viewModel ?? TopUpViewModel(onSubmit: onSubmit))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Amount", text: Bindable(viewModel).amountText)
                        .keyboardType(.decimalPad)
                } footer: {
                    Text("Demo top-up — credits your mock wallet instantly, no real payment method needed.")
                }
            }
            .navigationTitle("Top Up")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    if viewModel.isSubmitting {
                        ProgressView()
                    } else {
                        Button("Add") {
                            guard viewModel.canSubmit else { return }
                            Task {
                                await viewModel.submit()
                                dismiss()
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
#Preview("Empty") {
    TopUpSheet(onSubmit: { _ in }, viewModel: TopUpViewModel(previewScenario: .empty))
}

#Preview("Filled") {
    TopUpSheet(onSubmit: { _ in }, viewModel: TopUpViewModel(previewScenario: .filled))
}

#Preview("Invalid") {
    TopUpSheet(onSubmit: { _ in }, viewModel: TopUpViewModel(previewScenario: .invalid))
}

#Preview("Submitting") {
    TopUpSheet(onSubmit: { _ in }, viewModel: TopUpViewModel(previewScenario: .submitting))
}
#endif
