import SwiftUI
import Core
import CommonUI

/// Improve: media/file-aware — a message with an attachment shows a paperclip badge in
/// its snippet instead of search treating every hit as plain text.
struct GlobalSearchScreen: View {
    @State private var viewModel: GlobalSearchViewModel
    let navController: NavController
    /// The text typed in the presenting screen's search field. `nil` when the screen is driven
    /// by its own view model (previews).
    let query: String?

    init(viewModel: GlobalSearchViewModel = GlobalSearchViewModel(), navController: NavController, query: String? = nil) {
        self.navController = navController
        self.query = query
        _viewModel = State(wrappedValue: viewModel)
    }

    var body: some View {
        List {
            Section {
                Toggle("Media only", isOn: Bindable(viewModel).mediaOnlyChip)
            } footer: {
                Text("Tip: try \"from:@handle\", \"has:media\", \"after:2024-01-01\", or \"before:2024-01-01\" in the search field.")
            }

            if viewModel.isSearching {
                ProgressView()
            } else if viewModel.results.isEmpty {
                Text("No results for \"\(viewModel.trimmedQuery)\".")
                    .foregroundStyle(Color.secondary)
            } else {
                if !viewModel.results.conversations.isEmpty {
                    Section("Chats") {
                        ForEach(viewModel.results.conversations) { conversation in
                            Button {
                                navController.navigateTo(Destination.ChatThread(conversationId: conversation.id))
                            } label: {
                                Text(conversation.title).foregroundStyle(Color.primary)
                            }
                        }
                    }
                }
                if !viewModel.results.users.isEmpty {
                    Section("Contacts") {
                        ForEach(viewModel.results.users) { user in
                            Button {
                                Task { await startDirectConversation(with: user) }
                            } label: {
                                HStack(spacing: 16) {
                                    TalkoraAvatar(name: user.displayName, size: 36)
                                    VStack(alignment: .leading) {
                                        Text(user.displayName).foregroundStyle(Color.primary)
                                        Text(user.handle).font(.caption).foregroundStyle(Color.secondary)
                                    }
                                }
                            }
                        }
                    }
                }
                if !viewModel.results.messages.isEmpty {
                    Section("Messages") {
                        ForEach(viewModel.results.messages) { hit in
                            Button {
                                navController.navigateTo(Destination.ChatThread(conversationId: hit.conversationId))
                            } label: {
                                VStack(alignment: .leading, spacing: 2) {
                                    HStack {
                                        Text(hit.conversationTitle)
                                            .font(.caption.bold())
                                            .foregroundStyle(Color.accentColor)
                                        if hit.message.attachment != nil {
                                            Image(systemName: "paperclip")
                                                .font(.caption2)
                                                .foregroundStyle(Color.secondary)
                                        }
                                        Spacer()
                                        Text(hit.message.createdAt, style: .date)
                                            .font(.caption2)
                                            .foregroundStyle(Color.secondary)
                                    }
                                    Text(hit.message.text.isEmpty ? "📎 Attachment" : hit.message.text)
                                        .foregroundStyle(Color.primary)
                                        .lineLimit(2)
                                }
                            }
                        }
                    }
                }
            }
        }
        .onChange(of: query, initial: true) {
            if let query { viewModel.query = query }
        }
    }

    private func startDirectConversation(with user: User) async {
        guard let conversationId = await viewModel.directConversationId(with: user) else { return }
        navController.navigateTo(Destination.ChatThread(conversationId: conversationId))
    }
}

#if DEBUG
#Preview("Loaded") {
    NavigationStack { GlobalSearchScreen(viewModel: GlobalSearchViewModel(previewScenario: .loaded), navController: NavController()) }
}

#Preview("Loading") {
    NavigationStack { GlobalSearchScreen(viewModel: GlobalSearchViewModel(previewScenario: .loading), navController: NavController()) }
}

#Preview("No Results") {
    NavigationStack { GlobalSearchScreen(viewModel: GlobalSearchViewModel(previewScenario: .empty), navController: NavController()) }
}
#endif
