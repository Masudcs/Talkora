import SwiftUI
import Core

struct CreateCommunityScreen: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: CreateCommunityViewModel

    init(onCreate: @escaping (String, String?) async -> Void, viewModel: CreateCommunityViewModel? = nil) {
        _viewModel = State(wrappedValue: viewModel ?? CreateCommunityViewModel(onCreate: onCreate))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Community name", text: Bindable(viewModel).title)
                    TextField("Description (optional)", text: Bindable(viewModel).description)
                } footer: {
                    Text("A community groups several of your existing groups and channels under one roof. Link them after creating it.")
                }
            }
            .navigationTitle("New Community")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    if viewModel.isSubmitting {
                        ProgressView()
                    } else {
                        Button("Create") {
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
    CreateCommunityScreen(onCreate: { _, _ in }, viewModel: CreateCommunityViewModel(previewScenario: .empty))
}

#Preview("Filled") {
    CreateCommunityScreen(onCreate: { _, _ in }, viewModel: CreateCommunityViewModel(previewScenario: .filled))
}

#Preview("Invalid") {
    CreateCommunityScreen(onCreate: { _, _ in }, viewModel: CreateCommunityViewModel(previewScenario: .invalid))
}

#Preview("Submitting") {
    CreateCommunityScreen(onCreate: { _, _ in }, viewModel: CreateCommunityViewModel(previewScenario: .submitting))
}
#endif
