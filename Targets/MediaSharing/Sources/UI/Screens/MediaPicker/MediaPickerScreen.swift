import SwiftUI
import Core
import CommonUI
import Mock

/// Sheet root: grid of available assets that pushes `MediaComposeScreen` on selection. Owns its own `NavigationStack` because it is presented modally.
struct MediaPickerScreen: View {
    @State private var viewModel: MediaPickerViewModel
    @Environment(\.dismiss) private var dismiss
    let onSent: (Message) -> Void

    init(conversationId: String, viewModel: MediaPickerViewModel? = nil, onSent: @escaping (Message) -> Void) {
        _viewModel = State(wrappedValue: viewModel ?? MediaPickerViewModel(conversationId: conversationId))
        self.onSent = onSent
    }

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Send Media")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { dismiss() }
                    }
                }
                .navigationDestination(item: $viewModel.selectedAsset) { asset in
                    // Hand the sent message to the presenter first, then close the whole sheet.
                    MediaComposeScreen(asset: asset, conversationId: viewModel.conversationId) { message in
                        onSent(message)
                        dismiss()
                    }
                }
        }
        .task { await viewModel.load() }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.assetsState {
        case .idle, .loading:
            LoadingView()
        case .empty:
            EmptyStateView(title: "No media available", systemImage: "photo")
        case .failed(let error):
            ErrorStateView(message: error.userMessage, isRetryable: error.isRetryable) {
                Task { await viewModel.load() }
            }
        case .loaded(let assets):
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 4)], spacing: 4) {
                    ForEach(assets) { asset in
                        Button {
                            viewModel.select(asset)
                        } label: {
                            MediaThumbnail(kind: asset.kind, thumbnailURL: asset.thumbnailURL, durationSeconds: asset.durationSeconds, fileName: asset.fileName)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(4)
            }
        }
    }
}

#if DEBUG
#Preview("Loaded") {
    MediaPickerScreen(conversationId: PreviewData.directConversation.id, viewModel: MediaPickerViewModel(previewScenario: .loaded)) { _ in }
}

#Preview("Loading") {
    MediaPickerScreen(conversationId: PreviewData.directConversation.id, viewModel: MediaPickerViewModel(previewScenario: .loading)) { _ in }
}

#Preview("Empty") {
    MediaPickerScreen(conversationId: PreviewData.directConversation.id, viewModel: MediaPickerViewModel(previewScenario: .empty)) { _ in }
}

#Preview("Error") {
    MediaPickerScreen(conversationId: PreviewData.directConversation.id, viewModel: MediaPickerViewModel(previewScenario: .failed)) { _ in }
}
#endif
