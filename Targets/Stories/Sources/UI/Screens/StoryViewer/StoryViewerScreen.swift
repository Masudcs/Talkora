import SwiftUI
import Core
import CommonUI
import Mock

/// Full-screen story player: segmented progress bar on top, tap left/right halves to go back/forward, close button, and a viewers button on the user's own stories. Dismisses itself when the last story finishes.
struct StoryViewerScreen: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: StoryViewerViewModel

    /// `viewModel` is only for previews and tests.
    init(currentUserId: String, stories: [Story], viewModel: StoryViewerViewModel? = nil) {
        _viewModel = State(wrappedValue: viewModel ?? StoryViewerViewModel(stories: stories, currentUserId: currentUserId))
    }

    var body: some View {
        ZStack {
            if let story = viewModel.currentStory {
                storyBackground(story)
                overlayContent(story)
            }

            VStack {
                progressBar
                HStack {
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundStyle(.white)
                            .padding()
                    }
                }
                Spacer()
                if viewModel.isOwnStory {
                    Button {
                        viewModel.isViewersPresented = true
                        Task { await viewModel.loadViewers() }
                    } label: {
                        Label("\(viewModel.currentStory?.viewerIds.count ?? 0) Viewers", systemImage: "eye.fill")
                            .foregroundStyle(.white)
                    }
                    .padding(.bottom, 24)
                }
            }

            HStack(spacing: 0) {
                Color.clear.contentShape(Rectangle()).onTapGesture { viewModel.previous() }
                Color.clear.contentShape(Rectangle()).onTapGesture { viewModel.next() }
            }
        }
        .background(Color.black.ignoresSafeArea())
        .onAppear { viewModel.start() }
        .onDisappear { viewModel.stop() }
        .onChange(of: viewModel.isFinished) {
            if viewModel.isFinished { dismiss() }
        }
        .sheet(isPresented: $viewModel.isViewersPresented) {
            ViewersListSheet(viewers: viewModel.viewers)
        }
    }

    @ViewBuilder
    /// Media wins over the solid colour; falls back to black when neither is set.
    private func storyBackground(_ story: Story) -> some View {
        if let mediaURL = story.mediaURL {
            AsyncImage(url: mediaURL) { phase in
                if let image = phase.image {
                    image.resizable().scaledToFill()
                } else {
                    Color.black
                }
            }
            .ignoresSafeArea()
        } else {
            Color(hex: story.backgroundColorHex ?? "#000000").ignoresSafeArea()
        }
    }

    @ViewBuilder
    private func overlayContent(_ story: Story) -> some View {
        VStack(spacing: 16) {
            Spacer()
            Spacer()
            if let text = story.overlayText, !text.isEmpty {
                Text(text)
                    .font(.title2.bold())
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .padding()
                    .background(.black.opacity(0.3))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal, 24)
            }
            if let emoji = story.overlayEmoji {
                Text(emoji).font(.system(size: 60))
            }
            Spacer()
        }
    }

    private var progressBar: some View {
        HStack(spacing: 4) {
            ForEach(viewModel.stories.indices, id: \.self) { index in
                GeometryReader { geo in
                    Capsule()
                        .fill(.white.opacity(0.3))
                        .overlay(alignment: .leading) {
                            Capsule()
                                .fill(.white)
                                .frame(width: geo.size.width * segmentProgress(index))
                        }
                }
                .frame(height: 3)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    /// Past segments full, current one follows `progress`, future ones empty.
    private func segmentProgress(_ index: Int) -> Double {
        if index < viewModel.currentIndex { return 1 }
        if index == viewModel.currentIndex { return viewModel.progress }
        return 0
    }
}

/// Author-only list of who has viewed the current story.
private struct ViewersListSheet: View {
    let viewers: [User]

    var body: some View {
        NavigationStack {
            Group {
                if viewers.isEmpty {
                    EmptyStateView(title: "No viewers yet", systemImage: "eye")
                } else {
                    List(viewers) { user in
                        HStack(spacing: 16) {
                            TalkoraAvatar(name: user.displayName, size: 36)
                            Text(user.displayName)
                        }
                    }
                }
            }
            .navigationTitle("Viewers")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#if DEBUG
#Preview("Stories") {
    StoryViewerScreen(currentUserId: PreviewData.currentUser.id, stories: PreviewData.stories, viewModel: StoryViewerViewModel())
}
#endif
