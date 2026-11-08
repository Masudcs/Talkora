import SwiftUI
import Core
import CommonUI

/// Sheet for composing and posting a story. Dismisses only when posting succeeds; failures show inline.
struct CreateStoryScreen: View {
    @State private var viewModel: CreateStoryViewModel
    @Environment(\.dismiss) private var dismiss

    init(viewModel: CreateStoryViewModel = CreateStoryViewModel()) {
        _viewModel = State(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    preview
                    backgroundPicker
                    TextField("Add text", text: $viewModel.overlayText)
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    emojiPicker
                    privacyPicker

                    Toggle("Notify me if someone screenshots", isOn: $viewModel.notifyOnScreenshot)

                    if let error = viewModel.postError {
                        Text(error.userMessage)
                            .font(Font.caption)
                            .foregroundStyle(Color.red)
                    }
                }
                .padding(24)
            }
            .navigationTitle("New Status")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    if viewModel.isPosting {
                        ProgressView()
                    } else {
                        Button("Post") {
                            Task {
                                if await viewModel.post() != nil {
                                    dismiss()
                                }
                            }
                        }
                    }
                }
            }
            .sheet(isPresented: $viewModel.isManagingCloseFriends) {
                CloseFriendsScreen()
            }
            .task { await viewModel.loadMediaAssets() }
        }
    }

    /// Live WYSIWYG preview of the story as it will appear in the viewer.
    private var preview: some View {
        ZStack {
            if let asset = viewModel.selectedMediaAsset {
                AsyncImage(url: asset.thumbnailURL) { phase in
                    if let image = phase.image {
                        image.resizable().scaledToFill()
                    } else {
                        Color(.secondarySystemBackground)
                    }
                }
            } else {
                Color(hex: viewModel.selectedBackgroundColorHex)
            }
            VStack(spacing: 8) {
                Spacer()
                if !viewModel.overlayText.isEmpty {
                    Text(viewModel.overlayText)
                        .font(.title2.bold())
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                if let emoji = viewModel.overlayEmoji {
                    Text(emoji).font(.system(size: 44))
                }
                Spacer()
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 300)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var backgroundPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Background")
                .font(Font.caption)
                .foregroundStyle(Color.secondary)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(CreateStoryViewModel.backgroundColors, id: \.self) { hex in
                        Circle()
                            .fill(Color(hex: hex))
                            .frame(width: 36, height: 36)
                            .overlay(
                                Circle().stroke(.white, lineWidth: viewModel.selectedBackgroundColorHex == hex && viewModel.selectedMediaAsset == nil ? 3 : 0)
                            )
                            .onTapGesture { viewModel.selectBackgroundColor(hex) }
                    }
                    if case .loaded(let assets) = viewModel.mediaAssetsState {
                        ForEach(assets) { asset in
                            MediaThumbnail(kind: asset.kind, thumbnailURL: asset.thumbnailURL, durationSeconds: nil, fileName: asset.fileName, size: 36)
                                .clipShape(Circle())
                                .overlay(
                                    Circle().stroke(Color.accentColor, lineWidth: viewModel.selectedMediaAsset?.id == asset.id ? 3 : 0)
                                )
                                .onTapGesture { viewModel.selectMediaAsset(asset) }
                        }
                    }
                }
            }
        }
    }

    private var emojiPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Sticker")
                .font(Font.caption)
                .foregroundStyle(Color.secondary)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(CreateStoryViewModel.emojiOptions, id: \.self) { emoji in
                        Text(emoji)
                            .font(.title)
                            .padding(6)
                            .background(viewModel.overlayEmoji == emoji ? Color(.secondarySystemBackground) : Color.clear)
                            .clipShape(Circle())
                            .onTapGesture { viewModel.toggleEmoji(emoji) }
                    }
                }
            }
        }
    }

    private var privacyPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Who can see this story")
                .font(Font.caption)
                .foregroundStyle(Color.secondary)
            Picker("Privacy", selection: $viewModel.privacy) {
                Text("Everyone").tag(StoryPrivacy.everyone)
                Text("Close Friends").tag(StoryPrivacy.closeFriends)
                Text("Only Me").tag(StoryPrivacy.onlyMe)
            }
            .pickerStyle(.segmented)

            if viewModel.privacy == .closeFriends {
                Button("Manage Close Friends List") {
                    viewModel.isManagingCloseFriends = true
                }
                .font(Font.caption)
            }
        }
    }
}

#if DEBUG
#Preview("Empty") {
    CreateStoryScreen(viewModel: CreateStoryViewModel(previewScenario: .empty))
}

#Preview("Filled") {
    CreateStoryScreen(viewModel: CreateStoryViewModel(previewScenario: .filled))
}

#Preview("Posting") {
    CreateStoryScreen(viewModel: CreateStoryViewModel(previewScenario: .submitting))
}

#Preview("Error") {
    CreateStoryScreen(viewModel: CreateStoryViewModel(previewScenario: .failed))
}
#endif
