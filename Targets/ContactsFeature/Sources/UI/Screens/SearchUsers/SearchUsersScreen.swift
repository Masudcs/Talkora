import SwiftUI
import Core
import CommonUI

/// Username/name search. The search runs on every query change (no debounce); each result offers "Add" until a request has been sent.
struct SearchUsersScreen: View {
    @State private var viewModel: SearchUsersViewModel

    init(viewModel: SearchUsersViewModel = SearchUsersViewModel()) {
        _viewModel = State(wrappedValue: viewModel)
    }

    var body: some View {
        List {
            if let error = viewModel.requestError {
                Text(error.userMessage)
                    .font(Font.caption)
                    .foregroundStyle(Color.red)
            }
            ForEach(viewModel.results) { user in
                HStack(spacing: 16) {
                    TalkoraAvatar(name: user.displayName, size: 40)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(user.displayName)
                        Text(user.handle)
                            .font(Font.caption)
                            .foregroundStyle(Color.secondary)
                    }
                    Spacer()
                    if viewModel.sentRequestUserIds.contains(user.id) {
                        Text("Sent")
                            .font(Font.caption)
                            .foregroundStyle(Color.secondary)
                    } else {
                        Button("Add") { Task { await viewModel.sendRequest(to: user) } }
                            .font(Font.caption)
                    }
                }
            }
        }
        .listStyle(.plain)
        .searchable(text: Bindable(viewModel).query, prompt: "Search by name or @username")
        .onChange(of: viewModel.query) {
            Task { await viewModel.search() }
        }
        .navigationTitle("Search")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#if DEBUG
#Preview("Results") {
    NavigationStack { SearchUsersScreen(viewModel: SearchUsersViewModel(previewScenario: .loaded)) }
}

#Preview("Empty") {
    NavigationStack { SearchUsersScreen(viewModel: SearchUsersViewModel(previewScenario: .empty)) }
}

#Preview("Error") {
    NavigationStack { SearchUsersScreen(viewModel: SearchUsersViewModel(previewScenario: .failed)) }
}
#endif
