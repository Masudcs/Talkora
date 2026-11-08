import SwiftUI
import Core
import Mock

/// In-chat search, reachable from `ChatThreadScreen`'s toolbar. Jumping to a result only
/// works if that message is already loaded into the thread's current page — a known
/// limitation of this mock backend's simple cursor pagination.
struct InChatSearchScreen: View {
    let onJump: (String) -> Void
    @State private var viewModel: InChatSearchViewModel
    @Environment(\.dismiss) private var dismiss

    init(conversationId: String, viewModel: InChatSearchViewModel? = nil, onJump: @escaping (String) -> Void) {
        self.onJump = onJump
        _viewModel = State(wrappedValue: viewModel ?? InChatSearchViewModel(conversationId: conversationId))
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Toggle("Media only", isOn: Bindable(viewModel).mediaOnly)
                }
                if viewModel.isSearching {
                    ProgressView()
                } else if viewModel.results.isEmpty {
                    Text("No matches in this chat.")
                        .foregroundStyle(Color.secondary)
                } else {
                    ForEach(viewModel.results) { message in
                        Button {
                            onJump(message.id)
                        } label: {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(message.createdAt, style: .date)
                                    .font(.caption2)
                                    .foregroundStyle(Color.secondary)
                                Text(message.text.isEmpty ? "📎 Attachment" : message.text)
                                    .foregroundStyle(Color.primary)
                                    .lineLimit(2)
                            }
                        }
                    }
                }
            }
            .searchable(text: Bindable(viewModel).query, prompt: "Search in this chat")
            .navigationTitle("Search")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

#if DEBUG
#Preview("Loaded") {
    InChatSearchScreen(conversationId: PreviewData.directConversation.id, viewModel: InChatSearchViewModel(previewScenario: .loaded)) { _ in }
}

#Preview("Loading") {
    InChatSearchScreen(conversationId: PreviewData.directConversation.id, viewModel: InChatSearchViewModel(previewScenario: .loading)) { _ in }
}

#Preview("No Matches") {
    InChatSearchScreen(conversationId: PreviewData.directConversation.id, viewModel: InChatSearchViewModel(previewScenario: .empty)) { _ in }
}
#endif
