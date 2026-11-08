import SwiftUI
import Core
import CommonUI
import Mock

struct ChannelDetailScreen: View {
    @State private var viewModel: ChannelDetailViewModel

    init(channelId: String, viewModel: ChannelDetailViewModel? = nil) {
        _viewModel = State(wrappedValue: viewModel ?? ChannelDetailViewModel(channelId: channelId))
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            content
            if let error = viewModel.actionError {
                Text(error.userMessage)
                    .font(Font.caption)
                    .foregroundStyle(Color.red)
                    .padding(.horizontal, 16)
            }
            if viewModel.isAdmin {
                composer
            }
        }
        .background(Color(.systemBackground))
        .navigationTitle(viewModel.channel?.title ?? "Channel")
        .navigationBarTitleDisplayMode(.inline)
        .task { await viewModel.load() }
    }

    @ViewBuilder
    private var header: some View {
        if let channel = viewModel.channel {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Label("Channel · \(channel.followerCount) followers", systemImage: "dot.radiowaves.left.and.right")
                        .font(Font.caption)
                        .foregroundStyle(Color.secondary)
                    if let description = channel.description {
                        Text(description)
                            .font(Font.caption)
                            .foregroundStyle(Color.secondary)
                    }
                }
                Spacer()
                if !viewModel.isAdmin {
                    Button(channel.isFollowing ? "Following" : "Follow") {
                        Task { await viewModel.toggleFollow() }
                    }
                    .font(Font.headline)
                    .foregroundStyle(channel.isFollowing ? Color.secondary : Color.accentColor)
                }
            }
            .padding(16)
            .background(Color(.secondarySystemBackground))
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.postsState {
        case .idle, .loading:
            LoadingView()
        case .empty:
            EmptyStateView(title: "No posts yet", systemImage: "dot.radiowaves.left.and.right")
        case .failed(let error):
            ErrorStateView(message: error.userMessage, isRetryable: error.isRetryable) {
                Task { await viewModel.load() }
            }
        case .loaded(let posts):
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 16) {
                    ForEach(posts) { post in
                        ChannelPostRow(post: post, author: viewModel.author(for: post))
                            .onAppear { viewModel.registerView(post) }
                    }
                }
                .padding(16)
            }
        }
    }

    @ViewBuilder
    private var composer: some View {
        HStack(spacing: 8) {
            TextField("Write a post", text: $viewModel.draftText, axis: .vertical)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 20))
            Button {
                Task { await viewModel.post() }
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 30))
                    .foregroundStyle(Color.accentColor)
            }
            .disabled(viewModel.draftText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding(16)
    }
}

private struct ChannelPostRow: View {
    let post: ChannelPost
    let author: User?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(author?.displayName ?? "Admin")
                    .font(.caption.bold())
                    .foregroundStyle(Color.accentColor)
                Spacer()
                Text(post.createdAt, style: .date)
                    .font(.caption2)
                    .foregroundStyle(Color.secondary)
            }
            Text(post.text)
                .font(Font.body)
                .foregroundStyle(Color.primary)
            Label("\(post.viewCount)", systemImage: "eye")
                .font(.caption2)
                .foregroundStyle(Color.secondary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#if DEBUG
#Preview("Follower") {
    NavigationStack { ChannelDetailScreen(channelId: PreviewData.followerChannel.id, viewModel: ChannelDetailViewModel(previewScenario: .loaded)) }
}

#Preview("Admin") {
    NavigationStack { ChannelDetailScreen(channelId: PreviewData.adminChannel.id, viewModel: ChannelDetailViewModel(previewScenario: .loaded, isAdmin: true)) }
}

#Preview("Loading") {
    NavigationStack { ChannelDetailScreen(channelId: PreviewData.followerChannel.id, viewModel: ChannelDetailViewModel(previewScenario: .loading)) }
}

#Preview("No posts") {
    NavigationStack { ChannelDetailScreen(channelId: PreviewData.followerChannel.id, viewModel: ChannelDetailViewModel(previewScenario: .empty)) }
}

#Preview("Error") {
    NavigationStack { ChannelDetailScreen(channelId: PreviewData.followerChannel.id, viewModel: ChannelDetailViewModel(previewScenario: .failed)) }
}
#endif
