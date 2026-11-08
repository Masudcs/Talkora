import SwiftUI
import Core
import CommonUI
import Mock

/// Final step of sending media: choose quality and view-once, add a caption, send. Files skip quality and view-once since neither applies to them.
struct MediaComposeScreen: View {
    @State private var viewModel: MediaComposeViewModel
    let onSent: (Message) -> Void

    init(asset: MediaAsset, conversationId: String, viewModel: MediaComposeViewModel? = nil, onSent: @escaping (Message) -> Void) {
        self.onSent = onSent
        _viewModel = State(wrappedValue: viewModel ?? MediaComposeViewModel(asset: asset, conversationId: conversationId))
    }

    private var asset: MediaAsset {
        viewModel.asset
    }

    var body: some View {
        VStack(spacing: 24) {
            MediaThumbnail(kind: asset.kind, thumbnailURL: asset.thumbnailURL, durationSeconds: asset.durationSeconds, fileName: asset.fileName, size: 220)

            if asset.kind == .file {
                Text("File size: \(formattedSize(asset.originalSizeBytes))")
                    .font(Font.caption)
                    .foregroundStyle(Color.secondary)
            } else {
                Picker("Quality", selection: Bindable(viewModel).quality) {
                    Text("Compressed (\(formattedSize(viewModel.estimatedSize(for: .compressed))))").tag(MediaQuality.compressed)
                    Text("Original (\(formattedSize(viewModel.estimatedSize(for: .original))))").tag(MediaQuality.original)
                }
                .pickerStyle(.segmented)

                Toggle("View Once", isOn: Bindable(viewModel).isViewOnce)
            }

            TextField("Add a caption (optional)", text: Bindable(viewModel).caption)
                .padding()
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))

            if let error = viewModel.sendError {
                Text(error.userMessage)
                    .font(Font.caption)
                    .foregroundStyle(Color.red)
            }

            Spacer()

            if viewModel.isSending {
                ProgressView().frame(maxWidth: .infinity)
            } else {
                TalkoraButton("Send") {
                    Task {
                        // Only report success to the presenter; on failure the error shows inline and the user can retry.
                        if let message = await viewModel.send() {
                            onSent(message)
                        }
                    }
                }
            }
        }
        .padding(24)
        .navigationTitle(asset.fileName)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func formattedSize(_ bytes: Int?) -> String {
        guard let bytes else { return "" }
        return ByteCountFormatter.string(fromByteCount: Int64(bytes), countStyle: .file)
    }
}

#if DEBUG
private extension PreviewData {
    static var composeImage: MediaAsset { mediaAssets.first { $0.kind == .image } ?? mediaAssets[0] }
    static var composeFile: MediaAsset { mediaAssets.first { $0.kind == .file } ?? mediaAssets[0] }
}

@MainActor private func previewCompose(_ scenario: FormPreviewScenario, asset: MediaAsset) -> some View {
    NavigationStack {
        MediaComposeScreen(
            asset: asset,
            conversationId: PreviewData.directConversation.id,
            viewModel: MediaComposeViewModel(previewScenario: scenario, asset: asset)
        ) { _ in }
    }
}

#Preview("Image") {
    previewCompose(.empty, asset: PreviewData.composeImage)
}

#Preview("Filled") {
    previewCompose(.filled, asset: PreviewData.composeImage)
}

#Preview("File") {
    previewCompose(.empty, asset: PreviewData.composeFile)
}

#Preview("Sending") {
    previewCompose(.submitting, asset: PreviewData.composeImage)
}

#Preview("Error") {
    previewCompose(.failed, asset: PreviewData.composeImage)
}
#endif
