import SwiftUI
import Core
import CommonUI

/// Calls tab: history list. Tapping a row redials (outgoing); the toolbar button simulates an incoming call. Both present `CallScreen` full-screen via `activeCall`.
public struct CallLogScreen: View {
    @State private var viewModel: CallLogViewModel
    @State private var activeCall: ActiveCallRequest?

    init(viewModel: CallLogViewModel) {
        _viewModel = State(wrappedValue: viewModel)
    }

    public init() {
        self.init(viewModel: CallLogViewModel())
    }

    public var body: some View {
        NavigationStack {
            content
                .navigationTitle("Calls")
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            activeCall = viewModel.randomIncomingCallRequest()
                        } label: {
                            Image(systemName: "phone.badge.plus")
                        }
                    }
                }
                .task { await viewModel.load() }
                .fullScreenCover(item: $activeCall) { request in
                    CallScreen(request: request)
                }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle, .loading:
            LoadingView()
        case .empty:
            EmptyStateView(title: "No calls yet", systemImage: "phone")
        case .failed(let error):
            ErrorStateView(message: error.userMessage, isRetryable: error.isRetryable) {
                Task { await viewModel.load() }
            }
        case .loaded(let calls):
            List(calls) { call in
                Button {
                    activeCall = viewModel.redialRequest(for: call)
                } label: {
                    CallRow(call: call, name: viewModel.name(for: call))
                }
                .buttonStyle(.plain)
            }
            .listStyle(.plain)
        }
    }
}

/// One history row. Missed/unanswered incoming calls are tinted red; completed calls show their duration.
private struct CallRow: View {
    let call: Call
    let name: String

    var body: some View {
        HStack(spacing: 16) {
            TalkoraAvatar(name: name)
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(Font.headline)
                    .foregroundStyle(isMissedIncoming ? Color.red : Color.primary)
                HStack(spacing: 4) {
                    Image(systemName: call.direction == .incoming ? "arrow.down.left" : "arrow.up.right")
                    Text(outcomeLabel)
                }
                .font(Font.caption)
                .foregroundStyle(Color.secondary)
            }
            Spacer()
            Text(call.startedAt, style: .time)
                .font(Font.caption)
                .foregroundStyle(Color.secondary)
            Image(systemName: call.type == .video ? "video.fill" : "phone.fill")
                .foregroundStyle(Color.accentColor)
        }
        .padding(.vertical, 4)
    }

    private var isMissedIncoming: Bool {
        call.direction == .incoming && (call.outcome == .missed || call.outcome == .noAnswer)
    }

    private var outcomeLabel: String {
        switch call.outcome {
        case .completed: return formattedDuration(call.duration)
        case .missed: return "Missed"
        case .noAnswer: return "No Answer"
        case .declined: return "Declined"
        case .failed: return "Failed"
        }
    }

    private func formattedDuration(_ duration: TimeInterval) -> String {
        let total = Int(duration)
        return String(format: "%d:%02d", total / 60, total % 60)
    }
}

#if DEBUG
#Preview("Loaded") {
    CallLogScreen(viewModel: CallLogViewModel(previewScenario: .loaded))
}

#Preview("Loading") {
    CallLogScreen(viewModel: CallLogViewModel(previewScenario: .loading))
}

#Preview("Empty") {
    CallLogScreen(viewModel: CallLogViewModel(previewScenario: .empty))
}

#Preview("Error") {
    CallLogScreen(viewModel: CallLogViewModel(previewScenario: .failed))
}
#endif
