import SwiftUI
import Core
import CommonUI

struct AddMembersScreen: View {
    let navController: NavController
    @State private var viewModel: AddMembersViewModel

    init(navController: NavController, conversationId: String, viewModel: AddMembersViewModel? = nil) {
        self.navController = navController
        _viewModel = State(wrappedValue: viewModel ?? AddMembersViewModel(conversationId: conversationId))
    }

    var body: some View {
        Form {
            Section("Add to Group") {
                if viewModel.candidates.isEmpty {
                    Text("Everyone in your contacts is already in this group.")
                        .foregroundStyle(Color.secondary)
                } else {
                    ForEach(viewModel.candidates) { user in
                        UserSelectionRow(user: user, isSelected: viewModel.selectedUserIds.contains(user.id)) {
                            viewModel.toggle(user.id)
                        }
                    }
                }
            }

            if let error = viewModel.state.error {
                Section {
                    Text(error.userMessage)
                        .foregroundStyle(Color.red)
                }
            }
        }
        .navigationTitle("Add Members")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                if viewModel.state.isLoading {
                    ProgressView()
                } else {
                    Button("Add") {
                        Task {
                            await viewModel.addSelectedMembers()
                            if case .loaded = viewModel.state {
                                navController.popBackStack()
                            }
                        }
                    }
                    .disabled(!viewModel.canAdd)
                }
            }
        }
        .task { await viewModel.loadCandidates() }
    }
}

#if DEBUG
@MainActor private func addMembersPreview(_ scenario: FormPreviewScenario) -> some View {
    let vm = AddMembersViewModel(previewScenario: scenario)
    return NavigationStack { AddMembersScreen(navController: NavController(), conversationId: vm.conversationId, viewModel: vm) }
}

#Preview("Candidates") { addMembersPreview(.empty) }
#Preview("Everyone Added") { addMembersPreview(.invalid) }
#Preview("Selected") { addMembersPreview(.filled) }
#Preview("Submitting") { addMembersPreview(.submitting) }
#Preview("Error") { addMembersPreview(.failed) }
#endif
