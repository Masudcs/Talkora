import SwiftUI
import Core
import CommonUI

/// Address-book sync results: each contact is "Connect", "Requested" or "Not on Talkora" depending on whether it matched a user.
struct DeviceContactsScreen: View {
    @State private var viewModel: DeviceContactsViewModel

    init(viewModel: DeviceContactsViewModel = DeviceContactsViewModel()) {
        _viewModel = State(wrappedValue: viewModel)
    }

    var body: some View {
        content
            .navigationTitle("Sync Contacts")
            .navigationBarTitleDisplayMode(.inline)
            .task { await viewModel.sync() }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle, .loading:
            LoadingView()
        case .empty:
            EmptyStateView(title: "No contacts found", systemImage: "person.crop.circle")
        case .failed(let error):
            ErrorStateView(message: error.userMessage, isRetryable: error.isRetryable) {
                Task { await viewModel.sync() }
            }
        case .loaded(let contacts):
            List(contacts) { contact in
                HStack(spacing: 16) {
                    TalkoraAvatar(name: contact.name, size: 40)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(contact.name)
                        Text(contact.phoneNumber)
                            .font(Font.caption)
                            .foregroundStyle(Color.secondary)
                    }
                    Spacer()
                    if let matchedId = contact.matchedUserId {
                        if viewModel.connectedIds.contains(matchedId) {
                            Text("Requested")
                                .font(Font.caption)
                                .foregroundStyle(Color.secondary)
                        } else {
                            Button("Connect") { Task { await viewModel.connect(contact) } }
                                .font(Font.caption)
                        }
                    } else {
                        Text("Not on Talkora")
                            .font(Font.caption)
                            .foregroundStyle(Color.secondary)
                    }
                }
            }
            .listStyle(.plain)
        }
    }
}

#if DEBUG
#Preview("Loaded") {
    NavigationStack { DeviceContactsScreen(viewModel: DeviceContactsViewModel(previewScenario: .loaded)) }
}

#Preview("Loading") {
    NavigationStack { DeviceContactsScreen(viewModel: DeviceContactsViewModel(previewScenario: .loading)) }
}

#Preview("Empty") {
    NavigationStack { DeviceContactsScreen(viewModel: DeviceContactsViewModel(previewScenario: .empty)) }
}

#Preview("Error") {
    NavigationStack { DeviceContactsScreen(viewModel: DeviceContactsViewModel(previewScenario: .failed)) }
}
#endif
