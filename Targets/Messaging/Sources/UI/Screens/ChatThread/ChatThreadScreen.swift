import SwiftUI
import Core
import Payments
import MediaSharing
import Calls
import CommonUI
import Mock

/// One conversation: message list, composer, pinned/bot/blocked banners, and the sheets for settings,
/// in-chat search, media, reactions, payments and calls. Pushed by `Destination.ChatThread`.
struct ChatThreadScreen: View {
    let navController: NavController
    @State private var viewModel: ChatThreadViewModel
    @State private var activeCall: ActiveCallRequest?
    @State private var isSearchPresented = false
    /// Set by in-chat search to jump to a message; cleared once the scroll has happened.
    @State private var scrollTarget: String?
    @State private var isPaymentMenuPresented = false
    @FocusState private var isInputFocused: Bool

    init(navController: NavController, conversationId: String, viewModel: ChatThreadViewModel? = nil) {
        self.navController = navController
        _viewModel = State(wrappedValue: viewModel ?? ChatThreadViewModel(conversationId: conversationId))
    }

    var body: some View {
        VStack(spacing: 0) {
            e2eBanner
            botBanner
            pinnedBanner
            content
            if viewModel.isOtherPartyTyping {
                typingIndicator
            }
            if let error = viewModel.actionError {
                Text(error.userMessage)
                    .font(Font.caption)
                    .foregroundStyle(Color.red)
                    .padding(.horizontal, 16)
                    .padding(.top, 4)
            }
            mentionSuggestionsBar
            composerContextBar
            if viewModel.isBlockedParticipant {
                blockedBanner
            } else {
                inputBar
            }
        }
        .background {
            (viewModel.conversation?.wallpaper ?? .default).background
        }
        .navigationTitle(viewModel.otherParticipant?.displayName ?? viewModel.conversation?.title ?? "Chat")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if !viewModel.isGroup {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        activeCall = callRequest(type: .video)
                    } label: {
                        Image(systemName: "video.fill")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        activeCall = callRequest(type: .voice)
                    } label: {
                        Image(systemName: "phone.fill")
                    }
                }
            }
            if viewModel.isGroup {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        navController.navigateTo(Destination.GroupInfo(conversationId: viewModel.conversationId))
                    } label: {
                        Image(systemName: "info.circle")
                    }
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    isSearchPresented = true
                } label: {
                    Image(systemName: "magnifyingglass")
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    viewModel.isSettingsPresented = true
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $isSearchPresented) {
            Destination.InChatSearch(conversationId: viewModel.conversationId) { messageId in
                scrollTarget = messageId
                isSearchPresented = false
            }.presentedScreen()
        }
        .sheet(isPresented: $viewModel.isSettingsPresented) {
            if let conversation = viewModel.conversation {
                ChatSettingsSheet(
                    conversation: conversation,
                    otherParticipant: viewModel.otherParticipant,
                    isBlocked: viewModel.isBlockedParticipant,
                    onConversationChanged: { viewModel.applyConversation($0) },
                    onBlockChanged: { viewModel.setBlocked($0) }
                )
            }
        }
        .sheet(isPresented: $viewModel.isMediaPickerPresented) {
            Destination.MediaPicker(conversationId: viewModel.conversationId) { message in
                viewModel.appendSentMessage(message)
            }.presentedScreen()
        }
        .sheet(isPresented: Binding(
            get: { viewModel.reactingToMessageId != nil },
            set: { if !$0 { viewModel.reactingToMessageId = nil } }
        )) {
            if let messageId = viewModel.reactingToMessageId, let message = viewModel.messages.first(where: { $0.id == messageId }) {
                ReactionPickerView { emoji in
                    Task { await viewModel.toggleReaction(emoji, on: message) }
                }
            }
        }
        .fullScreenCover(item: $activeCall) { request in
            Destination.Call(request: request).presentedScreen()
        }
        .fullScreenCover(item: $viewModel.viewOnceViewerAttachment) { attachment in
            ViewOnceMediaViewer(attachment: attachment) {
                viewModel.viewOnceViewerAttachment = nil
            }
        }
        .confirmationDialog("Payments", isPresented: $isPaymentMenuPresented) {
            Button("Send Money") {
                viewModel.paymentComposeMode = .send
                viewModel.isPaymentComposePresented = true
            }
            Button("Request Money") {
                viewModel.paymentComposeMode = .request
                viewModel.isPaymentComposePresented = true
            }
        }
        .sheet(isPresented: $viewModel.isPaymentComposePresented) {
            if let otherParticipant = viewModel.otherParticipant {
                Destination.PaymentCompose(
                    mode: viewModel.paymentComposeMode,
                    counterpart: otherParticipant,
                    conversationId: viewModel.conversationId
                ) {
                    Task { await viewModel.load() }
                }.presentedScreen()
            }
        }
        .task { await viewModel.load() }
    }

    private var e2eBanner: some View {
        HStack(spacing: 4) {
            Image(systemName: "lock.fill")
                .font(.caption2)
            Text("Messages are end-to-end encrypted")
                .font(.caption2)
        }
        .foregroundStyle(Color.secondary)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
        .background(Color(.secondarySystemBackground).opacity(0.6))
    }

    /// Improve: bot chats are visually flagged up front, not indistinguishable from a
    /// human conversation.
    @ViewBuilder
    private var botBanner: some View {
        if viewModel.isBotConversation {
            HStack(spacing: 4) {
                Image(systemName: "wand.and.stars")
                    .font(.caption2)
                Text("\(viewModel.otherParticipant?.displayName ?? "This") is an automated bot")
                    .font(.caption2)
            }
            .foregroundStyle(.purple)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .background(Color.purple.opacity(0.12))
        }
    }

    private var blockedBanner: some View {
        VStack(spacing: 4) {
            Text("You blocked \(viewModel.otherParticipant?.displayName ?? "this contact"). They can't send you messages.")
                .font(Font.caption)
                .foregroundStyle(Color.secondary)
                .multilineTextAlignment(.center)
            Button("Unblock") {
                Task { await viewModel.toggleBlock() }
            }
            .font(Font.headline)
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(Color(.secondarySystemBackground))
    }

    /// Nil until both the conversation and counterpart are loaded. Only used in direct chats (group chats hide the call buttons).
    private func callRequest(type: CallType) -> ActiveCallRequest? {
        guard let otherParticipant = viewModel.otherParticipant, let conversation = viewModel.conversation else { return nil }
        return ActiveCallRequest(conversationId: conversation.id, counterpartId: otherParticipant.id, counterpartName: otherParticipant.displayName, type: type, direction: .outgoing)
    }

    @ViewBuilder
    private var pinnedBanner: some View {
        if let pinned = viewModel.pinnedMessage {
            HStack(spacing: 8) {
                Image(systemName: "pin.fill")
                    .foregroundStyle(Color.accentColor)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Pinned Message")
                        .font(.caption.bold())
                        .foregroundStyle(Color.accentColor)
                    Text(pinned.text)
                        .font(.caption)
                        .foregroundStyle(Color.secondary)
                        .lineLimit(1)
                }
                Spacer()
                if viewModel.canPin {
                    Button("Unpin") { Task { await viewModel.unpin() } }
                        .font(.caption)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 4)
            .background(Color(.secondarySystemBackground))
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.messagesState {
        case .idle, .loading:
            LoadingView()
        case .empty:
            EmptyStateView(title: "Say hello 👋", systemImage: "bubble.left.and.bubble.right")
        case .failed(let error):
            ErrorStateView(message: error.userMessage, isRetryable: error.isRetryable) {
                Task { await viewModel.load() }
            }
        case .loaded(let messages):
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(messages) { message in
                            MessageBubbleView(
                                message: message,
                                isMine: viewModel.isMine(message),
                                currentUserId: viewModel.currentUserId,
                                senderName: viewModel.senderName(for: message),
                                isMentioningMe: viewModel.isMentioningMe(message),
                                repliedMessage: viewModel.repliedMessage(for: message),
                                canPin: viewModel.canPin,
                                isPinned: viewModel.conversation?.pinnedMessageId == message.id,
                                onReply: { viewModel.beginReply(to: message) },
                                onEdit: { viewModel.beginEdit(message) },
                                onDelete: { Task { await viewModel.delete(message) } },
                                onTogglePin: { Task { await viewModel.togglePin(message) } },
                                onViewOnceTap: { viewModel.revealViewOnce(message) },
                                onReact: { viewModel.reactingToMessageId = message.id },
                                onToggleReaction: { emoji in Task { await viewModel.toggleReaction(emoji, on: message) } },
                                payment: viewModel.payment(for: message),
                                onRespondToPayment: { accept in
                                    guard let payment = viewModel.payment(for: message) else { return }
                                    Task { await viewModel.respondToPayment(payment, accept: accept) }
                                },
                                isBotSender: !viewModel.isMine(message) && viewModel.isBotConversation
                            )
                            .id(message.id)
                        }
                    }
                    .padding(16)
                }
                // Follow new messages (own sends, simulated replies) to the bottom.
                .onChange(of: messages.count) {
                    if let lastId = messages.last?.id {
                        withAnimation { proxy.scrollTo(lastId, anchor: .bottom) }
                    }
                }
                .onChange(of: scrollTarget) { _, target in
                    guard let target else { return }
                    withAnimation { proxy.scrollTo(target, anchor: .center) }
                    scrollTarget = nil
                }
                .onAppear {
                    if let lastId = messages.last?.id {
                        proxy.scrollTo(lastId, anchor: .bottom)
                    }
                }
            }
        }
    }

    private var typingIndicator: some View {
        HStack(spacing: 4) {
            ProgressView().controlSize(.mini)
            Text("\(viewModel.otherParticipant?.displayName ?? "They") is typing…")
                .font(Font.caption)
                .foregroundStyle(Color.secondary)
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.top, 4)
    }

    @ViewBuilder
    private var mentionSuggestionsBar: some View {
        if !viewModel.mentionSuggestions.isEmpty {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(viewModel.mentionSuggestions) { user in
                        Button(user.displayName) { viewModel.insertMention(user) }
                            .font(Font.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 6)
                            .background(Color(.secondarySystemBackground))
                            .clipShape(Capsule())
                    }
                }
                .padding(.horizontal, 16)
            }
            .padding(.top, 4)
        }
    }

    @ViewBuilder
    private var composerContextBar: some View {
        if let replyingTo = viewModel.replyingTo {
            ComposerContextBar(label: "Replying to", detail: replyingTo.isDeleted ? "This message was deleted" : replyingTo.text) {
                viewModel.cancelComposerContext()
            }
        } else if viewModel.isEditing {
            ComposerContextBar(label: "Editing message", detail: nil) {
                viewModel.cancelComposerContext()
            }
        }
    }

    private var inputBar: some View {
        HStack(spacing: 8) {
            Button {
                viewModel.isMediaPickerPresented = true
            } label: {
                Image(systemName: "paperclip")
                    .font(.system(size: 20))
                    .foregroundStyle(Color.accentColor)
            }

            if !viewModel.isGroup {
                Button {
                    isPaymentMenuPresented = true
                } label: {
                    Image(systemName: "dollarsign.circle")
                        .font(.system(size: 20))
                        .foregroundStyle(Color.accentColor)
                }
            }

            TextField("Message", text: $viewModel.draftText, axis: .vertical)
                .focused($isInputFocused)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 20))
                // Explicit onChange: see `updateMentionSuggestions`.
                .onChange(of: viewModel.draftText) {
                    viewModel.updateMentionSuggestions()
                }

            Button {
                Task {
                    if viewModel.isEditing {
                        await viewModel.confirmEdit()
                    } else {
                        await viewModel.send()
                    }
                }
            } label: {
                Image(systemName: viewModel.isEditing ? "checkmark.circle.fill" : "arrow.up.circle.fill")
                    .font(.system(size: 30))
                    .foregroundStyle(viewModel.canSend ? Color.accentColor : Color.secondary)
            }
            .disabled(!viewModel.canSend)
            .accessibilityIdentifier("chatSendButton")
        }
        .padding(16)
    }
}

private struct ComposerContextBar: View {
    let label: String
    let detail: String?
    let onCancel: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            Rectangle()
                .fill(Color.accentColor)
                .frame(width: 3)
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption.bold())
                    .foregroundStyle(Color.accentColor)
                if let detail {
                    Text(detail)
                        .font(.caption)
                        .foregroundStyle(Color.secondary)
                        .lineLimit(1)
                }
            }
            Spacer()
            Button(action: onCancel) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(Color.secondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 4)
        .background(Color(.secondarySystemBackground))
    }
}

#if DEBUG
#Preview("Direct chat") {
    NavigationStack { ChatThreadScreen(navController: NavController(), conversationId: PreviewData.directConversation.id, viewModel: ChatThreadViewModel(previewScenario: .loaded)) }
}

#Preview("Group chat") {
    NavigationStack { ChatThreadScreen(navController: NavController(), conversationId: PreviewData.groupConversation.id, viewModel: ChatThreadViewModel(previewScenario: .loaded, isGroup: true)) }
}

#Preview("Loading") {
    NavigationStack { ChatThreadScreen(navController: NavController(), conversationId: PreviewData.directConversation.id, viewModel: ChatThreadViewModel(previewScenario: .loading)) }
}

#Preview("Empty") {
    NavigationStack { ChatThreadScreen(navController: NavController(), conversationId: PreviewData.directConversation.id, viewModel: ChatThreadViewModel(previewScenario: .empty)) }
}

#Preview("Error") {
    NavigationStack { ChatThreadScreen(navController: NavController(), conversationId: PreviewData.directConversation.id, viewModel: ChatThreadViewModel(previewScenario: .failed)) }
}
#endif
