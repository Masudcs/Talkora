import SwiftUI
import Core
import CommonUI

/// Sheet for picking close friends. Saves on Done only; there is no explicit cancel, and dismissing by swipe discards changes.
struct CloseFriendsScreen: View {
    @State private var viewModel: CloseFriendsViewModel
    @Environment(\.dismiss) private var dismiss

    init(viewModel: CloseFriendsViewModel = CloseFriendsViewModel()) {
        _viewModel = State(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            List(viewModel.candidates) { user in
                UserSelectionRow(user: user, isSelected: viewModel.selectedIds.contains(user.id)) {
                    viewModel.toggle(user.id)
                }
            }
            .navigationTitle("Close Friends")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        Task {
                            await viewModel.save()
                            dismiss()
                        }
                    }
                }
            }
            .task { await viewModel.load() }
        }
    }
}

#if DEBUG
#Preview("Loaded") {
    CloseFriendsScreen(viewModel: CloseFriendsViewModel(previewScenario: .loaded))
}

#Preview("Empty") {
    CloseFriendsScreen(viewModel: CloseFriendsViewModel(previewScenario: .empty))
}
#endif
