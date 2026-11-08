import SwiftUI
import Core
import CommonUI
import Mock

/// Searchable grid of everything shared in one conversation. `.empty` (nothing shared) and an empty filtered result are distinct states.
struct MediaHistoryScreen: View {
    @State private var viewModel: MediaHistoryViewModel

    init(conversationId: String, viewModel: MediaHistoryViewModel? = nil) {
        _viewModel = State(wrappedValue: viewModel ?? MediaHistoryViewModel(conversationId: conversationId))
    }

    var body: some View {
        content
            .navigationTitle("Media & Files")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: Bindable(viewModel).searchQuery, prompt: "Search media & files")
            .task { await viewModel.load() }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle, .loading:
            LoadingView()
        case .empty:
            EmptyStateView(title: "No media shared yet", systemImage: "photo.on.rectangle")
        case .failed(let error):
            ErrorStateView(message: error.userMessage, isRetryable: error.isRetryable) {
                Task { await viewModel.load() }
            }
        case .loaded:
            let items = viewModel.filteredItems
            if items.isEmpty {
                EmptyStateView(title: "No results", systemImage: "magnifyingglass")
            } else {
                ScrollView {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 4)], spacing: 4) {
                        ForEach(items) { message in
                            if let attachment = message.attachment {
                                MediaThumbnail(kind: attachment.kind, thumbnailURL: attachment.url, durationSeconds: attachment.durationSeconds, fileName: attachment.fileName)
                            }
                        }
                    }
                    .padding(4)
                }
            }
        }
    }
}

#if DEBUG
#Preview("Loaded") {
    NavigationStack { MediaHistoryScreen(conversationId: PreviewData.directConversation.id, viewModel: MediaHistoryViewModel(previewScenario: .loaded)) }
}

#Preview("Loading") {
    NavigationStack { MediaHistoryScreen(conversationId: PreviewData.directConversation.id, viewModel: MediaHistoryViewModel(previewScenario: .loading)) }
}

#Preview("Empty") {
    NavigationStack { MediaHistoryScreen(conversationId: PreviewData.directConversation.id, viewModel: MediaHistoryViewModel(previewScenario: .empty)) }
}

#Preview("Error") {
    NavigationStack { MediaHistoryScreen(conversationId: PreviewData.directConversation.id, viewModel: MediaHistoryViewModel(previewScenario: .failed)) }
}
#endif
