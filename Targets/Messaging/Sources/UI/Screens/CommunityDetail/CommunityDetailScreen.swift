import SwiftUI
import Core
import Mock

struct CommunityDetailScreen: View {
    let navController: NavController
    @State private var viewModel: CommunityDetailViewModel

    init(navController: NavController, communityId: String, viewModel: CommunityDetailViewModel? = nil) {
        self.navController = navController
        _viewModel = State(wrappedValue: viewModel ?? CommunityDetailViewModel(communityId: communityId))
    }

    var body: some View {
        List {
            if let description = viewModel.community?.description {
                Section {
                    Text(description)
                        .foregroundStyle(Color.secondary)
                }
            }

            Section("Chats in this Community") {
                if let items = viewModel.community?.linkedItems, !items.isEmpty {
                    ForEach(items) { item in
                        Button {
                            switch item.kind {
                            case .group:
                                navController.navigateTo(Destination.ChatThread(conversationId: item.itemId))
                            case .channel:
                                navController.navigateTo(Destination.ChannelDetail(channelId: item.itemId))
                            }
                        } label: {
                            HStack {
                                Image(systemName: item.kind == .group ? "person.3.fill" : "dot.radiowaves.left.and.right")
                                    .foregroundStyle(item.kind == .group ? Color.accentColor : Color.green)
                                VStack(alignment: .leading) {
                                    Text(item.title)
                                        .foregroundStyle(Color.primary)
                                    Text(item.kind == .group ? "Group" : "Channel")
                                        .font(.caption2)
                                        .foregroundStyle(Color.secondary)
                                }
                            }
                        }
                    }
                } else {
                    Text("No chats linked yet.")
                        .foregroundStyle(Color.secondary)
                }
                Button {
                    viewModel.isLinkPresented = true
                } label: {
                    Label("Link a Group or Channel", systemImage: "link")
                }
            }

            if let error = viewModel.actionError {
                Section {
                    Text(error.userMessage).foregroundStyle(Color.red)
                }
            }
        }
        .navigationTitle(viewModel.community?.title ?? "Community")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $viewModel.isLinkPresented) {
            LinkChatSheet(viewModel: viewModel)
        }
        .task { await viewModel.load() }
    }
}

private struct LinkChatSheet: View {
    @State private var viewModel: CommunityDetailViewModel
    @Environment(\.dismiss) private var dismiss

    init(viewModel: CommunityDetailViewModel) {
        _viewModel = State(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            List {
                Section("Groups") {
                    if viewModel.linkableGroups.isEmpty {
                        Text("No more groups to link.")
                            .foregroundStyle(Color.secondary)
                    } else {
                        ForEach(viewModel.linkableGroups) { conversation in
                            Button(conversation.title) {
                                Task {
                                    await viewModel.linkGroup(conversation)
                                    dismiss()
                                }
                            }
                        }
                    }
                }
                Section("Channels") {
                    if viewModel.linkableChannels.isEmpty {
                        Text("No more channels to link.")
                            .foregroundStyle(Color.secondary)
                    } else {
                        ForEach(viewModel.linkableChannels) { channel in
                            Button(channel.title) {
                                Task {
                                    await viewModel.linkChannel(channel)
                                    dismiss()
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Link a Chat")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

#if DEBUG
#Preview("Loaded") {
    NavigationStack { CommunityDetailScreen(navController: NavController(), communityId: PreviewData.communities[0].id, viewModel: CommunityDetailViewModel()) }
}
#endif
