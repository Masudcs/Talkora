import SwiftUI
import Core
import CommonUI

/// Pending contact requests with Accept/Decline; an empty list shows the empty state (there is no separate loading state).
struct IncomingRequestsScreen: View {
    @State private var viewModel: IncomingRequestsViewModel

    init(viewModel: IncomingRequestsViewModel = IncomingRequestsViewModel()) {
        _viewModel = State(wrappedValue: viewModel)
    }

    var body: some View {
        Group {
            if viewModel.requests.isEmpty {
                EmptyStateView(title: "No pending requests", systemImage: "person.badge.clock")
            } else {
                List(viewModel.requests) { request in
                    HStack(spacing: 16) {
                        TalkoraAvatar(name: viewModel.name(for: request), size: 40)
                        Text(viewModel.name(for: request))
                        Spacer()
                        Button("Decline", role: .destructive) {
                            Task { await viewModel.respond(request, accept: false) }
                        }
                        .font(Font.caption)
                        Button("Accept") {
                            Task { await viewModel.respond(request, accept: true) }
                        }
                        .font(Font.caption)
                    }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("Requests")
        .navigationBarTitleDisplayMode(.inline)
        .task { await viewModel.load() }
    }
}

#if DEBUG
#Preview("Loaded") {
    NavigationStack { IncomingRequestsScreen(viewModel: IncomingRequestsViewModel(previewScenario: .loaded)) }
}

#Preview("Empty") {
    NavigationStack { IncomingRequestsScreen(viewModel: IncomingRequestsViewModel(previewScenario: .empty)) }
}
#endif
