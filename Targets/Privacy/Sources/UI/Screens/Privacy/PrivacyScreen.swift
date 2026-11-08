import SwiftUI
import Core

/// Improve: a single unified privacy & security hub — E2E indicator, last-seen, blocked
/// users, and app lock all live here instead of being scattered across separate screens.
/// Presented as a sheet, so it owns its `NavigationStack` and a Done button.
struct PrivacyScreen: View {
    @State private var viewModel: PrivacyViewModel
    @Environment(\.dismiss) private var dismiss

    init(viewModel: PrivacyViewModel = PrivacyViewModel()) {
        _viewModel = State(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Label("Chats are end-to-end encrypted", systemImage: "lock.fill")
                        .foregroundStyle(Color.accentColor)
                } footer: {
                    Text("Unlike apps that require opting into a separate \"secret chat,\" every conversation on Talkora — direct, group, or channel — is encrypted by default.")
                }

                Section {
                    Picker("Last Seen", selection: Binding(
                        get: { viewModel.lastSeen },
                        set: { newValue in Task { await viewModel.setLastSeen(newValue) } }
                    )) {
                        Text("Everyone").tag(LastSeenVisibility.everyone)
                        Text("Nobody").tag(LastSeenVisibility.nobody)
                    }
                } header: {
                    Text("Last Seen")
                }

                Section {
                    switch viewModel.blockedUsersState {
                    case .idle, .loading:
                        ProgressView()
                    case .empty:
                        Text("No blocked contacts.")
                            .foregroundStyle(Color.secondary)
                    case .failed(let error):
                        Text(error.userMessage)
                            .foregroundStyle(Color.red)
                    case .loaded(let users):
                        ForEach(users) { user in
                            HStack {
                                Text(user.displayName)
                                Spacer()
                                Button("Unblock") {
                                    Task { await viewModel.unblock(user) }
                                }
                                .disabled(viewModel.isUnblocking)
                            }
                        }
                    }
                } header: {
                    Text("Blocked Contacts")
                }

                Section {
                    // Turning on never flips the state directly: it opens the PIN sheet, and the lock only becomes enabled once a PIN is saved (`handlePINSaved`).
                    Toggle("App Lock (PIN)", isOn: Binding(
                        get: { viewModel.isAppLockEnabled },
                        set: { newValue in
                            if newValue {
                                viewModel.isPINSheetPresented = true
                            } else {
                                Task { await viewModel.disableAppLock() }
                            }
                        }
                    ))
                    if viewModel.isAppLockEnabled {
                        Button("Change PIN") {
                            viewModel.isPINSheetPresented = true
                        }
                    }
                } header: {
                    Text("App Lock")
                } footer: {
                    Text("When enabled, Talkora locks itself whenever it goes to the background.")
                }

                Section {
                    Button(role: .destructive) {
                        viewModel.lockdownNow()
                    } label: {
                        Label("Lockdown Now", systemImage: "lock.shield")
                    }
                    .disabled(!viewModel.isAppLockEnabled)
                } footer: {
                    Text(viewModel.isAppLockEnabled
                        ? "Immediately locks Talkora; your PIN is required to get back in."
                        : "Set an App Lock PIN above to enable this panic action.")
                }
            }
            .navigationTitle("Privacy & Security")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(isPresented: $viewModel.isPINSheetPresented) {
                SetAppLockPINSheet() {
                    viewModel.handlePINSaved()
                }
            }
            .task { await viewModel.load() }
        }
    }
}

#if DEBUG
#Preview("Loaded") {
    PrivacyScreen(viewModel: PrivacyViewModel(previewScenario: .loaded))
}

#Preview("Loading") {
    PrivacyScreen(viewModel: PrivacyViewModel(previewScenario: .loading))
}

#Preview("Empty") {
    PrivacyScreen(viewModel: PrivacyViewModel(previewScenario: .empty))
}

#Preview("Error") {
    PrivacyScreen(viewModel: PrivacyViewModel(previewScenario: .failed))
}
#endif
