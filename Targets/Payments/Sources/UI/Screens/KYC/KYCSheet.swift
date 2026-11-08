import SwiftUI
import Core

/// Improve: one short form, no region-specific document upload steps — this is a mock
/// payments layer, so a single simplified flow stands in for real KYC everywhere.
struct KYCSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: KYCViewModel

    init(onSubmit: @escaping (String, String) async -> Void, viewModel: KYCViewModel? = nil) {
        _viewModel = State(wrappedValue: viewModel ?? KYCViewModel(onSubmit: onSubmit))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Full legal name", text: Bindable(viewModel).fullName)
                    TextField("Country", text: Bindable(viewModel).country)
                } footer: {
                    Text("This is a simulated identity check — no documents required.")
                }
            }
            .navigationTitle("Verify Identity")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    if viewModel.isSubmitting {
                        ProgressView()
                    } else {
                        Button("Verify") {
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
    KYCSheet(onSubmit: { _, _ in }, viewModel: KYCViewModel(previewScenario: .empty))
}

#Preview("Filled") {
    KYCSheet(onSubmit: { _, _ in }, viewModel: KYCViewModel(previewScenario: .filled))
}

#Preview("Invalid") {
    KYCSheet(onSubmit: { _, _ in }, viewModel: KYCViewModel(previewScenario: .invalid))
}

#Preview("Submitting") {
    KYCSheet(onSubmit: { _, _ in }, viewModel: KYCViewModel(previewScenario: .submitting))
}
#endif
