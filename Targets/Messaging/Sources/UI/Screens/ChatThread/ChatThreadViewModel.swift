import Foundation
import Observation
import Core
import Mock

/// State and actions for one conversation (direct or group): loading, the composer (send, reply, edit),
/// pins, mentions, reactions, blocking, view-once media and payment messages.
@MainActor
@Observable
final class ChatThreadViewModel {
    /// Not observed: it's only read by `load()` and never drives UI. Set by the debug `init(previewScenario:)`.
    @ObservationIgnored private var isPreview = false
    let conversationId: String
    private(set) var conversation: Conversation?
    private(set) var otherParticipant: User?
    /// Only populated for group conversations; used for sender names, mentions and suggestions.
    private(set) var groupMembers: [User] = []
    private(set) var currentUserId: String = ""
    /// Used to detect mentions of the current user in group messages.
    private(set) var currentUserHandle: String = ""
    private(set) var messagesState: LoadableState<[Message]> = .idle
    /// Drives the typing indicator; only toggled by `simulateResponse`.
    private(set) var isOtherPartyTyping = false
    /// Last failure from a send/edit/delete/block action. Load failures go to `messagesState` instead.
    private(set) var actionError: AppError?
    private(set) var mentionSuggestions: [User] = []
    private(set) var isBlockedParticipant = false
    var viewOnceViewerAttachment: MediaAttachment?
    var reactingToMessageId: String?
    var isPaymentComposePresented = false
    var paymentComposeMode: PaymentComposeMode = .send
    /// Payment transactions keyed by id, so payment messages can render their current status.
    private(set) var paymentsById: [String: PaymentTransaction] = [:]
    /// Capability of the bot on the other side of a direct chat; nil for non-bot chats or if the bot lookup failed.
    private(set) var botCapability: BotCapability?

    var draftText: String = ""
    var replyingTo: Message?
    var editingMessage: Message?
    var isSettingsPresented = false
    var isMediaPickerPresented = false

    private let chatRepository: IChatRepository
    private let userRepository: IUserRepository
    private let privacyRepository: IPrivacyRepository
    private let paymentRepository: IPaymentTransferRepository
    private let botRepository: IBotRepository
    private let scheduler: NotificationScheduling

    init(conversationId: String, chatRepository: IChatRepository = ChatRepository(), userRepository: IUserRepository = UserRepository(), privacyRepository: IPrivacyRepository = PrivacyRepository(), paymentRepository: IPaymentTransferRepository = PaymentRepository(), botRepository: IBotRepository = BotRepository(), scheduler: NotificationScheduling = NotificationScheduler.shared) {
        self.scheduler = scheduler
        self.conversationId = conversationId
        self.chatRepository = chatRepository
        self.userRepository = userRepository
        self.privacyRepository = privacyRepository
        self.paymentRepository = paymentRepository
        self.botRepository = botRepository
    }

    var messages: [Message] {
        messagesState.value ?? []
    }

    /// False while the other participant is blocked or the draft is blank.
    var canSend: Bool {
        !isBlockedParticipant && !draftText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var isEditing: Bool {
        editingMessage != nil
    }

    var isGroup: Bool {
        conversation?.kind == .group
    }

    var isBotConversation: Bool {
        otherParticipant?.isBot ?? false
    }

    var pinnedMessage: Message? {
        guard let id = conversation?.pinnedMessageId else { return nil }
        return messages.first { $0.id == id }
    }

    /// Direct chats let either side pin; groups restrict pinning to admins and the owner.
    var canPin: Bool {
        guard let conversation else { return false }
        return conversation.kind == .direct || conversation.isAdminOrOwner(currentUserId)
    }

    func isMine(_ message: Message) -> Bool {
        message.senderId == currentUserId
    }

    /// Sender name label for group bubbles; nil in direct chats and for my own messages.
    func senderName(for message: Message) -> String? {
        guard isGroup, !isMine(message) else { return nil }
        return groupMembers.first { $0.id == message.senderId }?.displayName
    }

    /// Group-only, case-insensitive substring match on the current user's handle.
    func isMentioningMe(_ message: Message) -> Bool {
        guard isGroup, !currentUserHandle.isEmpty else { return false }
        return message.text.localizedCaseInsensitiveContains(currentUserHandle)
    }

    func repliedMessage(for message: Message) -> Message? {
        guard let replyId = message.replyToMessageId else { return nil }
        return messages.first { $0.id == replyId }
    }

    func payment(for message: Message) -> PaymentTransaction? {
        guard let id = message.paymentTransactionId else { return nil }
        return paymentsById[id]
    }

    /// Loads the current user, conversation, counterpart(s), first page of messages and payments.
    /// Failures fetching the counterpart, block state, bot list, group members or payments are
    /// tolerated (`try?`); only the user, conversation and messages calls move the screen to `.failed`.
    func load() async {
        guard !isPreview else { return }
        messagesState = .loading
        do {
            let me = try await userRepository.currentUser()
            currentUserId = me.id
            currentUserHandle = me.handle
            let conv = try await chatRepository.conversation(id: conversationId)
            conversation = conv
            if conv.kind == .direct, let otherId = conv.participantIds.first(where: { $0 != currentUserId }) {
                otherParticipant = try? await userRepository.user(id: otherId)
                isBlockedParticipant = (try? await privacyRepository.isBlocked(otherId)) ?? false
                if otherParticipant?.isBot == true {
                    let bots = (try? await botRepository.allBots()) ?? []
                    botCapability = bots.first { $0.id == otherId }?.capability
                }
            } else if conv.kind == .group {
                var fetched: [User] = []
                for member in conv.members {
                    if let user = try? await userRepository.user(id: member.userId) {
                        fetched.append(user)
                    }
                }
                groupMembers = fetched
            }
            let page = try await chatRepository.messages(conversationId: conversationId, cursor: nil)
            messagesState = page.items.isEmpty ? .empty : .loaded(page.items)
            scheduler.resetDigest(for: conversationId)
            if let transactions = try? await paymentRepository.transactions() {
                paymentsById = Dictionary(uniqueKeysWithValues: transactions.map { ($0.id, $0) })
            }
        } catch {
            messagesState = .failed(error.asAppError)
        }
    }

    /// Clears the composer before awaiting the repository, so the field empties immediately; on failure
    /// the text is not restored and the error goes to `actionError`.
    func send() async {
        guard canSend else { return }
        let text = draftText.trimmingCharacters(in: .whitespacesAndNewlines)
        let replyId = replyingTo?.id
        draftText = ""
        replyingTo = nil
        actionError = nil
        do {
            let sent = try await chatRepository.sendMessage(text: text, conversationId: conversationId, replyToMessageId: replyId)
            appendOrUpdate(sent)
            Task { await simulateResponse(to: sent) }
        } catch {
            actionError = error.asAppError
        }
    }

    /// Called by `MediaPickerScreen` after a media message was created server-side, so it
    /// appears instantly and rides the same delivery-tick/typing/reply simulation as a
    /// regular text message.
    func appendSentMessage(_ message: Message) {
        appendOrUpdate(message)
        Task { await simulateResponse(to: message) }
    }

    func beginReply(to message: Message) {
        editingMessage = nil
        replyingTo = message
    }

    func beginEdit(_ message: Message) {
        guard isMine(message), message.canEditOrDelete else { return }
        replyingTo = nil
        editingMessage = message
        draftText = message.text
    }

    func cancelComposerContext() {
        replyingTo = nil
        editingMessage = nil
        draftText = ""
    }

    func confirmEdit() async {
        guard let editingMessage else { return }
        let newText = draftText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !newText.isEmpty else { return }
        do {
            let updated = try await chatRepository.editMessage(messageId: editingMessage.id, conversationId: conversationId, newText: newText)
            appendOrUpdate(updated)
            self.editingMessage = nil
            draftText = ""
        } catch {
            actionError = error.asAppError
        }
    }

    /// Soft-deletes: replaces the message locally with a tombstone (empty text, `isDeleted`) instead of removing it.
    func delete(_ message: Message) async {
        guard isMine(message), message.canEditOrDelete else { return }
        do {
            try await chatRepository.deleteMessage(messageId: message.id, conversationId: conversationId)
            appendOrUpdate(Message(
                id: message.id,
                conversationId: message.conversationId,
                senderId: message.senderId,
                text: "",
                createdAt: message.createdAt,
                editedAt: message.editedAt,
                replyToMessageId: message.replyToMessageId,
                deliveryState: message.deliveryState,
                isDeleted: true,
                expiresAt: message.expiresAt
            ))
        } catch {
            actionError = error.asAppError
        }
    }

    /// Adopts a conversation changed by the settings or wallpaper screens.
    func applyConversation(_ updated: Conversation) {
        conversation = updated
    }

    /// Lets the settings sheet push a block change made there into this screen.
    func setBlocked(_ blocked: Bool) {
        isBlockedParticipant = blocked
    }

    /// Pins the message, or clears the pin if it is already the pinned one. Errors are ignored.
    func togglePin(_ message: Message) async {
        let targetId = conversation?.pinnedMessageId == message.id ? nil : message.id
        if let updated = try? await chatRepository.setPinnedMessage(targetId, in: conversationId) {
            conversation = updated
        }
    }

    func unpin() async {
        if let updated = try? await chatRepository.setPinnedMessage(nil, in: conversationId) {
            conversation = updated
        }
    }

    /// Rebuilds mention suggestions from the current trailing "@query" token in `draftText`.
    /// Called explicitly from the View's `.onChange(of: draftText)` rather than a property
    /// observer, since `@Observable` stored-property `didSet` behavior is not guaranteed.
    func updateMentionSuggestions() {
        guard isGroup, let atRange = draftText.range(of: "@", options: .backwards) else {
            mentionSuggestions = []
            return
        }
        let query = String(draftText[draftText.index(after: atRange.lowerBound)...])
        guard !query.contains(" ") else {
            mentionSuggestions = []
            return
        }
        mentionSuggestions = groupMembers.filter { $0.id != currentUserId }.filter {
            query.isEmpty || $0.displayName.lowercased().hasPrefix(query.lowercased())
        }
    }

    func insertMention(_ user: User) {
        guard let atRange = draftText.range(of: "@", options: .backwards) else { return }
        draftText.replaceSubrange(atRange.lowerBound..<draftText.endIndex, with: "\(user.handle) ")
        mentionSuggestions = []
    }

    /// Blocks or unblocks the other participant; local state only changes after the repository call succeeds.
    func toggleBlock() async {
        guard let otherParticipant else { return }
        do {
            if isBlockedParticipant {
                try await privacyRepository.unblockUser(otherParticipant.id)
                isBlockedParticipant = false
            } else {
                try await privacyRepository.blockUser(otherParticipant.id)
                isBlockedParticipant = true
            }
        } catch {
            actionError = error.asAppError
        }
    }

    /// Opens the full-screen viewer immediately, then marks the attachment consumed
    /// server-side — permanent for everyone, matching WhatsApp's view-once semantics.
    func revealViewOnce(_ message: Message) {
        guard let attachment = message.attachment, attachment.isViewOnce, !attachment.isConsumed else { return }
        viewOnceViewerAttachment = attachment
        Task {
            if let updated = try? await chatRepository.markViewOnceConsumed(messageId: message.id, conversationId: conversationId) {
                appendOrUpdate(updated)
            }
        }
    }

    func toggleReaction(_ emoji: String, on message: Message) async {
        if let updated = try? await chatRepository.toggleReaction(emoji, messageId: message.id, conversationId: conversationId) {
            appendOrUpdate(updated)
        }
    }

    /// Updates the cached transaction, then reloads the whole thread so the payment message reflects the result.
    func respondToPayment(_ transaction: PaymentTransaction, accept: Bool) async {
        guard let updated = try? await paymentRepository.respondToRequest(transaction.id, accept: accept) else { return }
        paymentsById[updated.id] = updated
        await load()
    }

    /// Replaces the message with the same id, or appends it. Used for every local mutation of the list.
    private func appendOrUpdate(_ message: Message) {
        var current = messages
        if let idx = current.firstIndex(where: { $0.id == message.id }) {
            current[idx] = message
        } else {
            current.append(message)
        }
        messagesState = .loaded(current)
    }

    /// Models what a real client would receive over a live socket after sending a
    /// message: delivery/read ticks progressing, the other person typing, then replying.
    /// Only meaningful for 1:1 conversations — group delivery ticks stay "sent" (no single
    /// counterpart to progress them), matching how group chats generally skip per-message
    /// read receipts.
    private func simulateResponse(to message: Message) async {
        guard conversation?.kind == .direct, !isBlockedParticipant else { return }
        if let updatedTicks = try? await chatRepository.simulateDeliveryTicks(messageId: message.id, conversationId: conversationId) {
            appendOrUpdate(updatedTicks)
        }
        isOtherPartyTyping = true
        let reply = try? await chatRepository.simulateIncomingReply(conversationId: conversationId)
        isOtherPartyTyping = false
        if let reply {
            appendOrUpdate(reply)
            if botCapability == .reminders {
                await scheduler.scheduleReminder(text: message.text, delay: 15, conversationId: conversationId)
            }
            await scheduler.notifyNewMessage(
                conversationId: conversationId,
                conversationTitle: conversation?.title ?? "",
                senderName: otherParticipant?.displayName ?? conversation?.title ?? "New message",
                messageText: reply.text,
                isGroup: false,
                isMuted: conversation?.isMuted ?? false,
                isMention: false,
                sound: conversation?.notificationSound ?? .standard
            )
        }
    }
}

#if DEBUG
extension ChatThreadViewModel {
    convenience init(previewScenario scenario: PreviewScenario, isGroup: Bool = false) {
        let conversation = isGroup ? PreviewData.groupConversation : PreviewData.directConversation
        let me = PreviewData.currentUser
        self.init(conversationId: conversation.id)
        isPreview = true
        currentUserId = me.id
        currentUserHandle = me.handle
        self.conversation = conversation
        let others = conversation.participantIds.filter { $0 != me.id }
        if isGroup {
            groupMembers = others.compactMap { PreviewData.user($0) }
        } else {
            otherParticipant = PreviewData.user(others.first)
        }
        messagesState = scenario.state(PreviewData.messages(in: conversation.id))
    }
}
#endif
