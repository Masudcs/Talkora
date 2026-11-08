import SwiftUI
import Core
import CommonUI

struct CreateGroupScreen: View {
    let navController: NavController
    @State private var viewModel: CreateGroupViewModel

    init(navController: NavController, viewModel: CreateGroupViewModel = CreateGroupViewModel()) {
        self.navController = navController
        _viewModel = State(wrappedValue: viewModel)
    }

    var body: some View {
        Form {
            Section {
                TextField("Group name", text: $viewModel.title)
                TextField("Description (optional)", text: $viewModel.description)
            }

            Section("Add Members") {
                ForEach(viewModel.candidates) { user in
                    UserSelectionRow(user: user, isSelected: viewModel.selectedUserIds.contains(user.id)) {
                        viewModel.toggle(user.id)
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
        .navigationTitle("New Group")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                if viewModel.state.isLoading {
                    ProgressView()
                } else {
                    Button("Create") {
                        Task {
                            await viewModel.create()
                            if case .loaded(let conversation) = viewModel.state {
                                navController.navigateTo(
                                    Destination.ChatThread(conversationId: conversation.id),
                                    popUpTo: Destination.CreateGroup.self,
                                    inclusive: true
                                )
                            }
                        }
                    }
                    .disabled(!viewModel.canCreate)
                }
            }
        }
        .task { await viewModel.loadCandidates() }
    }
}

#if DEBUG
#Preview("Empty") {
    NavigationStack { CreateGroupScreen(navController: NavController(), viewModel: CreateGroupViewModel(previewScenario: .empty)) }
}

#Preview("Invalid") {
    NavigationStack { CreateGroupScreen(navController: NavController(), viewModel: CreateGroupViewModel(previewScenario: .invalid)) }
}

#Preview("Filled") {
    NavigationStack { CreateGroupScreen(navController: NavController(), viewModel: CreateGroupViewModel(previewScenario: .filled)) }
}

#Preview("Submitting") {
    NavigationStack { CreateGroupScreen(navController: NavController(), viewModel: CreateGroupViewModel(previewScenario: .submitting)) }
}

#Preview("Error") {
    NavigationStack { CreateGroupScreen(navController: NavController(), viewModel: CreateGroupViewModel(previewScenario: .failed)) }
}
#endif
