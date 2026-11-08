import SwiftUI
import Core
import Mock

/// Two sections: emoji totals, and the most-reacted messages (hidden when there are none).
struct ReactionAnalyticsScreen: View {
    @State private var viewModel: ReactionAnalyticsViewModel

    init(conversationId: String, viewModel: ReactionAnalyticsViewModel? = nil) {
        _viewModel = State(wrappedValue: viewModel ?? ReactionAnalyticsViewModel(conversationId: conversationId))
    }

    var body: some View {
        Form {
            Section {
                switch viewModel.state {
                case .idle, .loading:
                    ProgressView()
                case .empty:
                    Text("No reactions yet in this group.")
                        .foregroundStyle(Color.secondary)
                case .failed(let error):
                    VStack(alignment: .leading, spacing: 8) {
                        Text(error.userMessage)
                            .foregroundStyle(Color.red)
                        if error.isRetryable {
                            Button("Try Again") { Task { await viewModel.load() } }
                        }
                    }
                case .loaded(let summary):
                    ForEach(summary.emojiTotals) { total in
                        HStack {
                            Text(total.emoji).font(.title3)
                            Spacer()
                            Text("\(total.count)").foregroundStyle(Color.secondary)
                        }
                    }
                }
            } header: {
                Text("Most Used Reactions")
            }

            if let summary = viewModel.state.value, !summary.topMessages.isEmpty {
                Section("Most Reacted Messages") {
                    ForEach(summary.topMessages) { message in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(message.text.isEmpty ? "📎 Attachment" : message.text)
                                .lineLimit(2)
                                .foregroundStyle(Color.primary)
                            Text("\(viewModel.totalReactionCount(for: message)) reactions")
                                .font(.caption)
                                .foregroundStyle(Color.secondary)
                        }
                    }
                }
            }
        }
        .navigationTitle("Reaction Analytics")
        .navigationBarTitleDisplayMode(.inline)
        .task { await viewModel.load() }
    }
}

#if DEBUG
#Preview("Loaded") {
    NavigationStack { ReactionAnalyticsScreen(conversationId: PreviewData.groupConversation.id, viewModel: ReactionAnalyticsViewModel(previewScenario: .loaded)) }
}

#Preview("Loading") {
    NavigationStack { ReactionAnalyticsScreen(conversationId: PreviewData.groupConversation.id, viewModel: ReactionAnalyticsViewModel(previewScenario: .loading)) }
}

#Preview("Empty") {
    NavigationStack { ReactionAnalyticsScreen(conversationId: PreviewData.groupConversation.id, viewModel: ReactionAnalyticsViewModel(previewScenario: .empty)) }
}

#Preview("Error") {
    NavigationStack { ReactionAnalyticsScreen(conversationId: PreviewData.groupConversation.id, viewModel: ReactionAnalyticsViewModel(previewScenario: .failed)) }
}
#endif
