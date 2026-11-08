import Foundation
import Observation
import Core

/// Owns the per-conversation settings sheet. The chat thread stays the source of truth for
/// the conversation, so every successful change is reported back through the callbacks.
@MainActor
@Observable
final class ChatSettingsViewModel {
    let conversationId: String
    let otherParticipant: User?
    private(set) var conversation: Conversation
    private(set) var isBlockedParticipant: Bool
    private(set) var actionError: AppError?
    var isReportSheetPresented = false

    private let chatRepository: IConversationRepository
    private let privacyRepository: IPrivacyRepository
    private let onConversationChanged: (Conversation) -> Void
    private let onBlockChanged: (Bool) -> Void

    init(
        conversation: Conversation,
        otherParticipant: User?,
        isBlockedParticipant: Bool,
        chatRepository: IConversationRepository = ChatRepository(),
        privacyRepository: IPrivacyRepository = PrivacyRepository(),
        onConversationChanged: @escaping (Conversation) -> Void,
        onBlockChanged: @escaping (Bool) -> Void
    ) {
        self.conversationId = conversation.id
        self.conversation = conversation
        self.otherParticipant = otherParticipant
        self.isBlockedParticipant = isBlockedParticipant
        self.chatRepository = chatRepository
        self.privacyRepository = privacyRepository
        self.onConversationChanged = onConversationChanged
        self.onBlockChanged = onBlockChanged
    }

    var isGroup: Bool {
        conversation.kind == .group
    }

    /// Adopts a conversation updated elsewhere (e.g. the wallpaper picker) and informs the thread.
    func applyConversation(_ updated: Conversation) {
        conversation = updated
        onConversationChanged(updated)
    }

    func updateReadReceipts(_ enabled: Bool) async {
        await updateSettings(readReceiptsEnabled: enabled, disappearingDuration: conversation.disappearingMessagesDuration)
    }

    func updateDisappearingDuration(_ duration: TimeInterval?) async {
        await updateSettings(readReceiptsEnabled: conversation.readReceiptsEnabled, disappearingDuration: duration)
    }

    func updateMuted(_ muted: Bool) async {
        do {
            applyConversation(try await chatRepository.setMuted(muted, for: conversationId))
        } catch {
            actionError = error.asAppError
        }
    }

    func updateNotificationSound(_ sound: NotificationSound) async {
        do {
            applyConversation(try await chatRepository.setNotificationSound(sound, for: conversationId))
        } catch {
            actionError = error.asAppError
        }
    }

    func toggleBlock() async {
        guard let otherParticipant else { return }
        do {
            if isBlockedParticipant {
                try await privacyRepository.unblockUser(otherParticipant.id)
            } else {
                try await privacyRepository.blockUser(otherParticipant.id)
            }
            isBlockedParticipant.toggle()
            onBlockChanged(isBlockedParticipant)
        } catch {
            actionError = error.asAppError
        }
    }

    func reportParticipant(reason: String) async {
        guard let otherParticipant, !reason.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        try? await privacyRepository.reportUser(otherParticipant.id, reason: reason)
        isReportSheetPresented = false
    }

    func dismissError() {
        actionError = nil
    }

    private func updateSettings(readReceiptsEnabled: Bool, disappearingDuration: TimeInterval?) async {
        do {
            applyConversation(try await chatRepository.updateSettings(
                conversationId: conversationId,
                readReceiptsEnabled: readReceiptsEnabled,
                disappearingDuration: disappearingDuration
            ))
        } catch {
            actionError = error.asAppError
        }
    }
}
