import SwiftUI
import UserNotifications
import Core

/// Shows the OS permission state and offers the matching action: request when undetermined, deep-link to iOS Settings when denied. Test/simulation tools appear only when authorized.
struct NotificationSettingsScreen: View {
    @State private var viewModel: NotificationSettingsViewModel
    @Environment(\.dismiss) private var dismiss

    init(viewModel: NotificationSettingsViewModel = NotificationSettingsViewModel()) {
        _viewModel = State(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Text("Status")
                        Spacer()
                        Text(statusLabel)
                            .foregroundStyle(viewModel.isAuthorized ? Color.accentColor : Color.secondary)
                    }
                    if viewModel.authorizationStatus == .notDetermined {
                        Button("Enable Notifications") {
                            Task { await viewModel.requestAuthorization() }
                        }
                    } else if viewModel.authorizationStatus == .denied {
                        Button("Open iOS Settings") {
                            // Once denied, iOS never re-prompts; the user must change it in Settings.
                            if let url = URL(string: UIApplication.openSettingsURLString) {
                                UIApplication.shared.open(url)
                            }
                        }
                    }
                } footer: {
                    Text("Notifications are per-conversation muted and use a per-conversation sound setting — see a chat's settings sheet.")
                }

                if viewModel.isAuthorized {
                    Section {
                        Button("Send Test Notification") {
                            Task { await viewModel.sendTestNotification() }
                        }
                    }

                    Section {
                        if viewModel.groupConversations.isEmpty {
                            Text("No group chats yet.")
                                .foregroundStyle(Color.secondary)
                        } else {
                            ForEach(viewModel.groupConversations) { conversation in
                                Button {
                                    Task { await viewModel.simulateBusyGroup(conversation) }
                                } label: {
                                    HStack {
                                        Text(conversation.title)
                                        Spacer()
                                        if viewModel.isSimulating {
                                            ProgressView()
                                        }
                                    }
                                }
                                .disabled(viewModel.isSimulating)
                            }
                        }
                    } header: {
                        Text("Simulate Busy Group")
                    } footer: {
                        Text("Fires several messages at once in the chosen group. Improve: they collapse into one summary notification instead of one banner per message.")
                    }
                }
            }
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .task { await viewModel.load() }
        }
    }

    private var statusLabel: String {
        switch viewModel.authorizationStatus {
        case .authorized: return "Enabled"
        case .denied: return "Denied"
        case .provisional: return "Provisional"
        case .ephemeral: return "Ephemeral"
        case .notDetermined: return "Not Enabled"
        @unknown default: return "Unknown"
        }
    }
}

#if DEBUG
#Preview("Allowed") {
    NotificationSettingsScreen(viewModel: NotificationSettingsViewModel(previewStatus: .authorized))
}

#Preview("Denied") {
    NotificationSettingsScreen(viewModel: NotificationSettingsViewModel(previewStatus: .denied))
}

#Preview("Not requested") {
    NotificationSettingsScreen(viewModel: NotificationSettingsViewModel(previewStatus: .notDetermined))
}
#endif
