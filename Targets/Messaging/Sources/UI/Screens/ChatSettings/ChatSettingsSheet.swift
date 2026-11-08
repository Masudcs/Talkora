import SwiftUI
import Core
import MediaSharing
import Mock

/// Uncommon (Telegram-style) disappearing messages + the per-conversation read-receipt
/// toggle that fixes WhatsApp/Messenger's all-or-nothing global setting.
struct ChatSettingsSheet: View {
    @State private var viewModel: ChatSettingsViewModel
    @Environment(\.dismiss) private var dismiss

    init(
        conversation: Conversation,
        otherParticipant: User?,
        isBlocked: Bool,
        onConversationChanged: @escaping (Conversation) -> Void,
        onBlockChanged: @escaping (Bool) -> Void
    ) {
        _viewModel = State(wrappedValue: ChatSettingsViewModel(
            conversation: conversation,
            otherParticipant: otherParticipant,
            isBlockedParticipant: isBlocked,
            onConversationChanged: onConversationChanged,
            onBlockChanged: onBlockChanged
        ))
    }

    init(viewModel: ChatSettingsViewModel) {
        _viewModel = State(wrappedValue: viewModel)
    }

    private static let durationOptions: [(label: String, value: TimeInterval?)] = [
        ("Off", nil),
        ("10 Seconds (Demo)", 10),
        ("24 Hours", 24 * 60 * 60),
        ("7 Days", 7 * 24 * 60 * 60),
    ]

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    NavigationLink {
                        Destination.MediaHistory(conversationId: viewModel.conversationId).presentedScreen()
                    } label: {
                        Label("Media & Files", systemImage: "photo.on.rectangle")
                    }
                    NavigationLink {
                        ChatWallpaperPickerScreen(
                            conversationId: viewModel.conversationId,
                            selected: viewModel.conversation.wallpaper
                        ) { viewModel.applyConversation($0) }
                    } label: {
                        Label("Chat Wallpaper", systemImage: "photo.fill")
                    }
                }

                Section {
                    Toggle(
                        "Mute Notifications",
                        isOn: Binding(
                            get: { viewModel.conversation.isMuted },
                            set: { newValue in Task { await viewModel.updateMuted(newValue) } }
                        )
                    )
                    Picker(
                        "Notification Alert",
                        selection: Binding(
                            get: { viewModel.conversation.notificationSound },
                            set: { newValue in Task { await viewModel.updateNotificationSound(newValue) } }
                        )
                    ) {
                        Text("Default").tag(NotificationSound.standard)
                        Text("Silent").tag(NotificationSound.silent)
                    }
                } footer: {
                    Text("Silent still shows a notification for this chat, just without sound or vibration.")
                }

                Section {
                    Toggle(
                        "Read Receipts",
                        isOn: Binding(
                            get: { viewModel.conversation.readReceiptsEnabled },
                            set: { newValue in Task { await viewModel.updateReadReceipts(newValue) } }
                        )
                    )
                } footer: {
                    Text("Applies to this conversation only. Turning it off means you won't see when \(viewModel.otherParticipant?.displayName ?? "they") read your messages either.")
                }

                Section {
                    ForEach(Self.durationOptions, id: \.label) { option in
                        Button {
                            Task { await viewModel.updateDisappearingDuration(option.value) }
                        } label: {
                            HStack {
                                Text(option.label)
                                    .foregroundStyle(Color.primary)
                                Spacer()
                                if viewModel.conversation.disappearingMessagesDuration == option.value {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(Color.accentColor)
                                }
                            }
                        }
                    }
                } header: {
                    Text("Disappearing Messages")
                } footer: {
                    Text("New messages sent after this is turned on will disappear for everyone after the selected time.")
                }

                if !viewModel.isGroup, let otherParticipant = viewModel.otherParticipant {
                    Section {
                        Button(role: .destructive) {
                            Task { await viewModel.toggleBlock() }
                        } label: {
                            Text(viewModel.isBlockedParticipant ? "Unblock \(otherParticipant.displayName)" : "Block \(otherParticipant.displayName)")
                        }
                        Button(role: .destructive) {
                            viewModel.isReportSheetPresented = true
                        } label: {
                            Text("Report \(otherParticipant.displayName)")
                        }
                    } header: {
                        Text("Block & Report")
                    }
                }
            }
            .navigationTitle("Chat Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .alert(
                "Something went wrong",
                isPresented: Binding(get: { viewModel.actionError != nil }, set: { if !$0 { viewModel.dismissError() } })
            ) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.actionError?.userMessage ?? "")
            }
            .sheet(isPresented: Bindable(viewModel).isReportSheetPresented) {
                ReportUserSheet { reason in
                    Task { await viewModel.reportParticipant(reason: reason) }
                }
            }
        }
    }
}

private struct ReportUserSheet: View {
    let onSubmit: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var reason = ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("What's wrong with this contact?", text: $reason, axis: .vertical)
                } header: {
                    Text("Reason")
                }
            }
            .navigationTitle("Report Contact")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Submit") {
                        onSubmit(reason)
                        dismiss()
                    }
                    .disabled(reason.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}

#if DEBUG
#Preview("Direct Chat") {
    ChatSettingsSheet(viewModel: ChatSettingsViewModel(
        conversation: PreviewData.directConversation,
        otherParticipant: PreviewData.user(PreviewData.directConversation.participantIds.first { $0 != PreviewData.currentUser.id }),
        isBlockedParticipant: false,
        onConversationChanged: { _ in },
        onBlockChanged: { _ in }
    ))
}

#Preview("Blocked Contact") {
    ChatSettingsSheet(viewModel: ChatSettingsViewModel(
        conversation: PreviewData.directConversation,
        otherParticipant: PreviewData.user(PreviewData.directConversation.participantIds.first { $0 != PreviewData.currentUser.id }),
        isBlockedParticipant: true,
        onConversationChanged: { _ in },
        onBlockChanged: { _ in }
    ))
}

#Preview("Group Chat") {
    ChatSettingsSheet(viewModel: ChatSettingsViewModel(
        conversation: PreviewData.groupConversation,
        otherParticipant: nil,
        isBlockedParticipant: false,
        onConversationChanged: { _ in },
        onBlockChanged: { _ in }
    ))
}
#endif
