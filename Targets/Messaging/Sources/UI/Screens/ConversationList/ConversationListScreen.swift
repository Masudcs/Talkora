import CommonUI
import Core
import SwiftUI

public struct ConversationListScreen: View {
    @State private var navController = NavController()
    @State private var viewModel: ConversationListViewModel
    @State private var searchQuery = ""

    init(viewModel: ConversationListViewModel) {
        _viewModel = State(wrappedValue: viewModel)
    }

    public init() {
        self.init(viewModel: ConversationListViewModel())
    }

    public var body: some View {
        NavigationStack(path: $navController.navStack) {
            Group {
                if searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    content
                } else {
                    Destination.GlobalSearch(query: searchQuery).getScreen(navController: navController)
                }
            }
            .navigationTitle("Chats")
            .searchable(text: $searchQuery, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search messages, chats, people")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        navController.navigateTo(Destination.BotDirectory())
                    } label: {
                        Image(systemName: "wand.and.stars")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        navController.navigateTo(Destination.ChannelDirectory())
                    } label: {
                        Image(systemName: "dot.radiowaves.left.and.right")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        navController.navigateTo(Destination.CreateGroup())
                    } label: {
                        Image(systemName: "person.3.fill")
                    }
                }
            }
            .task { await viewModel.load() }
            .navigationDestination(for: BaseDestination.self) { destination in
                destination.getScreen(navController: navController)
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle, .loading:
            LoadingView()
        case .empty:
            EmptyStateView(title: "No conversations yet", systemImage: "bubble.left.and.bubble.right")
        case .failed(let error):
            ErrorStateView(message: error.userMessage, isRetryable: error.isRetryable) {
                Task { await viewModel.load() }
            }
        case .loaded(let conversations):
            List {
                Section {
                    ForEach(conversations) { conversation in
                        Button {
                            navController.navigateTo(Destination.ChatThread(conversationId: conversation.id))
                        } label: {
                            ConversationRow(conversation: conversation)
                        }
                        .buttonStyle(.plain)
                    }
                } header: {
                    Text(AppEnvironment.current.displayName)
                }
            }
            .listStyle(.plain)
        }
    }
}

private struct ConversationRow: View {
    let conversation: Conversation

    var body: some View {
        HStack(spacing: 16) {
            TalkoraAvatar(name: conversation.title)
            VStack(alignment: .leading, spacing: 4) {
                Text(conversation.title)
                    .font(Font.headline)
                    .foregroundStyle(Color.primary)
                if let preview = conversation.lastMessagePreview {
                    Text(preview)
                        .font(Font.caption)
                        .foregroundStyle(Color.secondary)
                        .lineLimit(1)
                }
            }
            Spacer()
            if conversation.isMuted {
                Image(systemName: "bell.slash.fill")
                    .font(.caption)
                    .foregroundStyle(Color.secondary)
            }
            if conversation.disappearingMessagesDuration != nil {
                Image(systemName: "timer")
                    .font(.caption)
                    .foregroundStyle(Color.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

#if DEBUG
#Preview("Loaded") {
    ConversationListScreen(viewModel: ConversationListViewModel(previewScenario: .loaded))
}

#Preview("Loading") {
    ConversationListScreen(viewModel: ConversationListViewModel(previewScenario: .loading))
}

#Preview("Empty") {
    ConversationListScreen(viewModel: ConversationListViewModel(previewScenario: .empty))
}

#Preview("Error") {
    ConversationListScreen(viewModel: ConversationListViewModel(previewScenario: .failed))
}
#endif
