import SwiftUI
import Core
import CommonUI

/// Status tab root: "My Status", then others' updates. Public because the app's tab bar embeds it. Presents story creation as a sheet and the viewer as a full-screen cover.
public struct StatusScreen: View {
    @State private var viewModel: StatusViewModel
    @State private var isCreatingStory = false
    @State private var viewerGroup: StoryViewerGroup?

    /// Internal initialiser for previews and tests.
    init(viewModel: StatusViewModel) {
        _viewModel = State(wrappedValue: viewModel)
    }

    public init() {
        self.init(viewModel: StatusViewModel())
    }

    public var body: some View {
        NavigationStack {
            List {
                Section {
                    Button {
                        if viewModel.myActiveStories.isEmpty {
                            isCreatingStory = true
                        } else {
                            viewerGroup = StoryViewerGroup(stories: viewModel.myActiveStories)
                        }
                    } label: {
                        MyStatusRow(hasStory: !viewModel.myActiveStories.isEmpty)
                    }
                    .buttonStyle(.plain)
                }

                if let error = viewModel.state.error {
                    Section {
                        ErrorStateView(message: error.userMessage, isRetryable: error.isRetryable) {
                            Task { await viewModel.load() }
                        }
                        .frame(height: 200)
                    }
                }

                if !viewModel.othersStoriesGrouped.isEmpty {
                    Section("Recent Updates") {
                        ForEach(viewModel.othersStoriesGrouped, id: \.author) { group in
                            Button {
                                viewerGroup = StoryViewerGroup(stories: group.stories)
                            } label: {
                                OtherStoryRow(
                                    name: viewModel.name(for: group.author),
                                    count: group.stories.count,
                                    isViewed: viewModel.hasViewedAll(group.stories)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .listStyle(.plain)
            .navigationTitle("Status")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isCreatingStory = true
                    } label: {
                        Image(systemName: "square.and.pencil")
                    }
                }
            }
            .task { await viewModel.load() }
            .sheet(isPresented: $isCreatingStory, onDismiss: { Task { await viewModel.load() } }) {
                CreateStoryScreen()
            }
            .fullScreenCover(item: $viewerGroup) { group in
                StoryViewerScreen(currentUserId: viewModel.currentUserId, stories: group.stories)
            }
        }
    }
}

/// Wraps a set of stories for `fullScreenCover(item:)`; a fresh `id` per tap makes SwiftUI present a new viewer each time.
struct StoryViewerGroup: Identifiable {
    let id = UUID()
    let stories: [Story]
}

/// Own-status row: ring when active stories exist, "+" badge when none.
private struct MyStatusRow: View {
    let hasStory: Bool

    var body: some View {
        HStack(spacing: 16) {
            ZStack(alignment: .bottomTrailing) {
                TalkoraAvatar(name: "You", size: 56)
                    .overlay(Circle().strokeBorder(hasStory ? Color.accentColor : .clear, lineWidth: 2))
                if !hasStory {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(Color.accentColor)
                        .background(Circle().fill(Color(.systemBackground)))
                }
            }
            VStack(alignment: .leading, spacing: 2) {
                Text("My Status")
                    .font(Font.headline)
                    .foregroundStyle(Color.primary)
                Text(hasStory ? "Tap to view" : "Tap to add a status update")
                    .font(Font.caption)
                    .foregroundStyle(Color.secondary)
            }
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

/// One author's row; accent ring means unseen stories, grey means all seen.
private struct OtherStoryRow: View {
    let name: String
    let count: Int
    let isViewed: Bool

    var body: some View {
        HStack(spacing: 16) {
            TalkoraAvatar(name: name, size: 56)
                .overlay(Circle().strokeBorder(isViewed ? Color.secondary.opacity(0.4) : Color.accentColor, lineWidth: 2))
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(Font.headline)
                    .foregroundStyle(Color.primary)
                Text(count > 1 ? "\(count) updates" : "1 update")
                    .font(Font.caption)
                    .foregroundStyle(Color.secondary)
            }
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

#if DEBUG
#Preview("Loaded") {
    StatusScreen(viewModel: StatusViewModel(previewScenario: .loaded))
}

#Preview("Empty") {
    StatusScreen(viewModel: StatusViewModel(previewScenario: .empty))
}

#Preview("Error") {
    StatusScreen(viewModel: StatusViewModel(previewScenario: .failed))
}
#endif
