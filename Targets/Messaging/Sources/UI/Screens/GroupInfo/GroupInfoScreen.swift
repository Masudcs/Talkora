import SwiftUI
import Core
import Reactions
import MediaSharing
import CommonUI
import Mock

struct GroupInfoScreen: View {
    let navController: NavController
    @State private var viewModel: GroupInfoViewModel
    @Environment(\.dismiss) private var dismiss

    init(navController: NavController, conversationId: String, viewModel: GroupInfoViewModel? = nil) {
        self.navController = navController
        _viewModel = State(wrappedValue: viewModel ?? GroupInfoViewModel(conversationId: conversationId))
    }

    var body: some View {
        Form {
            infoSection
            Section {
                PushRowButton {
                    navController.navigateTo(Destination.MediaHistory(conversationId: viewModel.conversationId))
                } label: {
                    Label("Media & Files", systemImage: "photo.on.rectangle")
                }
                if viewModel.isCurrentUserAdmin {
                    PushRowButton {
                        navController.navigateTo(Destination.ReactionAnalytics(conversationId: viewModel.conversationId))
                    } label: {
                        Label("Reaction Analytics", systemImage: "chart.bar.fill")
                    }
                }
            }
            membersSection
            if let error = viewModel.actionError {
                Section {
                    Text(error.userMessage).foregroundStyle(Color.red)
                }
            }
            Section {
                Button("Leave Group", role: .destructive) {
                    Task { await viewModel.leaveGroup() }
                }
            }
        }
        .navigationTitle("Group Info")
        .navigationBarTitleDisplayMode(.inline)
        .task { await viewModel.load() }
        .onChange(of: viewModel.didLeave) {
            if viewModel.didLeave {
                navController.popUpToRoot()
            }
        }
    }

    @ViewBuilder
    private var infoSection: some View {
        Section {
            if viewModel.isEditingInfo {
                TextField("Group name", text: $viewModel.editedTitle)
                TextField("Description", text: $viewModel.editedDescription)
                Button("Save") { Task { await viewModel.saveInfo() } }
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    Text(viewModel.conversation?.title ?? "")
                        .font(Font.headline)
                    if let description = viewModel.conversation?.groupDescription, !description.isEmpty {
                        Text(description)
                            .font(Font.caption)
                            .foregroundStyle(Color.secondary)
                    }
                }
                if viewModel.isCurrentUserAdmin {
                    Button("Edit Name & Description") { viewModel.isEditingInfo = true }
                }
            }
        }
    }

    @ViewBuilder
    private var membersSection: some View {
        Section {
            ForEach(viewModel.members) { member in
                HStack(spacing: 16) {
                    TalkoraAvatar(name: member.user.displayName, size: 36)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(member.user.displayName)
                        Text(member.role.rawValue.capitalized)
                            .font(Font.caption)
                            .foregroundStyle(Color.secondary)
                    }
                    Spacer()
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    if viewModel.isCurrentUserAdmin, member.id != viewModel.currentUserId, member.role != .owner {
                        Button("Remove", role: .destructive) {
                            Task { await viewModel.removeMember(member.id) }
                        }
                        if member.role == .admin {
                            Button("Demote") { Task { await viewModel.demote(member.id) } }
                        } else {
                            Button("Promote") { Task { await viewModel.promote(member.id) } }
                        }
                    }
                }
            }
            if viewModel.isCurrentUserAdmin {
                Button {
                    navController.navigateTo(Destination.AddMembers(conversationId: viewModel.conversationId))
                } label: {
                    Label("Add Members", systemImage: "person.badge.plus")
                }
            }
        } header: {
            Text("\(viewModel.members.count) Members")
        }
    }
}

#if DEBUG
#Preview("Loaded") {
    NavigationStack { GroupInfoScreen(navController: NavController(), conversationId: PreviewData.groupConversation.id, viewModel: GroupInfoViewModel(previewScenario: .loaded)) }
}

#Preview("Error") {
    NavigationStack { GroupInfoScreen(navController: NavController(), conversationId: PreviewData.groupConversation.id, viewModel: GroupInfoViewModel(previewScenario: .failed)) }
}
#endif
