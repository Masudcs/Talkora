import SwiftUI
import Core
import CommonUI

/// Improve: bots are discoverable from a directory, not hidden behind an invite/add
/// flow — same idea as Module 11's channel directory.
struct BotDirectoryScreen: View {
    let navController: NavController
    @State private var viewModel: BotDirectoryViewModel

    init(navController: NavController, viewModel: BotDirectoryViewModel = BotDirectoryViewModel()) {
        self.navController = navController
        _viewModel = State(wrappedValue: viewModel)
    }

    var body: some View {
        content
            .navigationTitle("Bots")
            .navigationBarTitleDisplayMode(.inline)
            .task { await viewModel.load() }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle, .loading:
            LoadingView()
        case .empty:
            EmptyStateView(title: "No bots available", systemImage: "wand.and.stars")
        case .failed(let error):
            ErrorStateView(message: error.userMessage, isRetryable: error.isRetryable) {
                Task { await viewModel.load() }
            }
        case .loaded(let bots):
            botList(bots)
        }
    }

    private func botList(_ bots: [Bot]) -> some View {
        List(bots) { bot in
            Button {
                Task {
                    if let conversation = await viewModel.startChat(with: bot) {
                        navController.navigateTo(Destination.ChatThread(conversationId: conversation.id))
                    }
                }
            } label: {
                HStack(spacing: 16) {
                    ZStack {
                        Circle().fill(Color.purple.opacity(0.15))
                        Image(systemName: "wand.and.stars")
                            .foregroundStyle(.purple)
                    }
                    .frame(width: 44, height: 44)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(bot.name)
                            .font(Font.headline)
                            .foregroundStyle(Color.primary)
                        Text(bot.description)
                            .font(Font.caption)
                            .foregroundStyle(Color.secondary)
                    }
                }
                .padding(.vertical, 4)
            }
            .buttonStyle(.plain)
        }
    }
}

#if DEBUG
#Preview("Loaded") {
    NavigationStack { BotDirectoryScreen(navController: NavController(), viewModel: BotDirectoryViewModel(previewScenario: .loaded)) }
}

#Preview("Loading") {
    NavigationStack { BotDirectoryScreen(navController: NavController(), viewModel: BotDirectoryViewModel(previewScenario: .loading)) }
}

#Preview("Empty") {
    NavigationStack { BotDirectoryScreen(navController: NavController(), viewModel: BotDirectoryViewModel(previewScenario: .empty)) }
}

#Preview("Error") {
    NavigationStack { BotDirectoryScreen(navController: NavController(), viewModel: BotDirectoryViewModel(previewScenario: .failed)) }
}
#endif
