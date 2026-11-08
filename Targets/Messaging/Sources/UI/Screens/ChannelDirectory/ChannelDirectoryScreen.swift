import SwiftUI
import Core

/// Improve: channels, groups, and communities each get distinct iconography and labeling
/// here and throughout, instead of blurring together under one "chat" mental model.
struct ChannelDirectoryScreen: View {
    let navController: NavController
    @State private var viewModel: ChannelDirectoryViewModel
    @State private var isAddMenuPresented = false

    init(navController: NavController, viewModel: ChannelDirectoryViewModel = ChannelDirectoryViewModel()) {
        self.navController = navController
        _viewModel = State(wrappedValue: viewModel)
    }

    var body: some View {
        List {
            if !viewModel.myChannels.isEmpty {
                Section("My Channels") {
                    ForEach(viewModel.myChannels) { channel in
                        Button {
                            navController.navigateTo(Destination.ChannelDetail(channelId: channel.id))
                        } label: {
                            ChannelRow(channel: channel)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            if !viewModel.communities.isEmpty {
                Section("Communities") {
                    ForEach(viewModel.communities) { community in
                        Button {
                            navController.navigateTo(Destination.CommunityDetail(communityId: community.id))
                        } label: {
                            CommunityRow(community: community)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            Section("Discover Channels") {
                if viewModel.discoverableChannels.isEmpty {
                    Text("No new channels to discover right now.")
                        .foregroundStyle(Color.secondary)
                } else {
                    ForEach(viewModel.discoverableChannels) { channel in
                        HStack {
                            Button {
                                navController.navigateTo(Destination.ChannelDetail(channelId: channel.id))
                            } label: {
                                ChannelRow(channel: channel)
                            }
                            .buttonStyle(.plain)
                            Spacer()
                            Button("Follow") {
                                Task { await viewModel.toggleFollow(channel) }
                            }
                            .font(Font.caption)
                        }
                    }
                }
            }
        }
        .navigationTitle("Channels & Communities")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    isAddMenuPresented = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .confirmationDialog("New", isPresented: $isAddMenuPresented) {
            Button("New Channel") { viewModel.isCreateChannelPresented = true }
            Button("New Community") { viewModel.isCreateCommunityPresented = true }
        }
        .sheet(isPresented: $viewModel.isCreateChannelPresented) {
            CreateChannelScreen { title, description in
                if let channel = await viewModel.createChannel(title: title, description: description) {
                    navController.navigateTo(Destination.ChannelDetail(channelId: channel.id))
                }
            }
        }
        .sheet(isPresented: $viewModel.isCreateCommunityPresented) {
            CreateCommunityScreen { title, description in
                if let community = await viewModel.createCommunity(title: title, description: description) {
                    navController.navigateTo(Destination.CommunityDetail(communityId: community.id))
                }
            }
        }
        .task { await viewModel.load() }
        .refreshable { await viewModel.load() }
    }
}

private struct ChannelRow: View {
    let channel: Channel

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle().fill(Color.accentColor.opacity(0.15))
                Image(systemName: "dot.radiowaves.left.and.right")
                    .foregroundStyle(Color.accentColor)
            }
            .frame(width: 44, height: 44)

            VStack(alignment: .leading, spacing: 2) {
                Text(channel.title)
                    .font(Font.headline)
                    .foregroundStyle(Color.primary)
                Text("Channel · \(channel.followerCount) followers")
                    .font(Font.caption)
                    .foregroundStyle(Color.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

private struct CommunityRow: View {
    let community: Community

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle().fill(Color.green.opacity(0.15))
                Image(systemName: "rectangle.3.group.fill")
                    .foregroundStyle(Color.green)
            }
            .frame(width: 44, height: 44)

            VStack(alignment: .leading, spacing: 2) {
                Text(community.title)
                    .font(Font.headline)
                    .foregroundStyle(Color.primary)
                Text("Community · \(community.linkedItems.count) chats")
                    .font(Font.caption)
                    .foregroundStyle(Color.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

#if DEBUG
#Preview("Loaded") {
    NavigationStack { ChannelDirectoryScreen(navController: NavController(), viewModel: ChannelDirectoryViewModel(previewScenario: .loaded)) }
}

#Preview("Empty") {
    NavigationStack { ChannelDirectoryScreen(navController: NavController(), viewModel: ChannelDirectoryViewModel(previewScenario: .empty)) }
}
#endif
