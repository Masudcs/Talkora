import SwiftUI
import Core

struct CreateChannelScreen: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: CreateChannelViewModel

    init(onCreate: @escaping (String, String?) async -> Void, viewModel: CreateChannelViewModel? = nil) {
        _viewModel = State(wrappedValue: viewModel ?? CreateChannelViewModel(onCreate: onCreate))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Channel name", text: Bindable(viewModel).title)
                    TextField("Description (optional)", text: Bindable(viewModel).description)
                } footer: {
                    Text("Everyone can follow, but only you (and admins you add later) can post.")
                }
            }
            .navigationTitle("New Channel")
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
    CreateChannelScreen(onCreate: { _, _ in }, viewModel: CreateChannelViewModel(previewScenario: .empty))
}

#Preview("Filled") {
    CreateChannelScreen(onCreate: { _, _ in }, viewModel: CreateChannelViewModel(previewScenario: .filled))
}

#Preview("Invalid") {
    CreateChannelScreen(onCreate: { _, _ in }, viewModel: CreateChannelViewModel(previewScenario: .invalid))
}

#Preview("Submitting") {
    CreateChannelScreen(onCreate: { _, _ in }, viewModel: CreateChannelViewModel(previewScenario: .submitting))
}
#endif
