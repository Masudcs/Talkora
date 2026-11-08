import Foundation

/// The in-memory "database" behind every mock endpoint. An actor so concurrent reads/writes
/// from multiple repositories are safe by construction. Seeded once per process; mutations
/// (send a message, add a reaction, ...) persist for the lifetime of the app session, exactly
/// like a real backend would, so the UI reflects actions taken during the session.
public actor MockDataStore {
    /// Process-wide store used by `APIClientProvider`; tests build their own isolated instances.
    public static let shared = MockDataStore()

    private var users: [String: UserDTO]
    private var conversations: [String: ConversationDTO]
    private var messagesByConversation: [String: [MessageDTO]]
    private var otpChallenges: [String: (phoneNumber: String, code: String, expiresAt: Date)] = [:]
    private var appLockPIN: String?
    private var calls: [CallDTO]
    private let mediaAssets: [MediaAssetDTO]
    private var stories: [StoryDTO]
    private var closeFriendIds: [String] = []
    private let deviceContacts: [DeviceContactDTO]
    private var contactRequests: [ContactRequestDTO] = []
    private var connections: Set<String> = []
    private var discoverabilitySetting: String = "everyone"
    private var sentRequestTimestamps: [Date] = []
    private let requestThrottleLimit = 3
    private let requestThrottleWindow: TimeInterval = 120
    private var lastSeenVisibilitySetting: String = "everyone"
    private var blockedUserIdSet: Set<String> = []
    private var reports: [ReportDTO] = []
    private var channels: [String: ChannelDTO]
    private var channelPosts: [String: [ChannelPostDTO]]
    private var communities: [String: CommunityDTO]
    private var wallets: [String: WalletDTO]
    private var paymentTransactions: [PaymentTransactionDTO]
    private let bots: [BotDTO]
    /// Improve: search is index-backed, not a linear scan over every message on every
    /// keystroke — word -> message ids, rebuilt incrementally as messages are sent/edited.
    private var messageWordIndex: [String: Set<String>] = [:]

    /// Same window enforced client-side (`Message.canEditOrDelete`) — kept here too as
    /// defense in depth, exactly like a real API would re-validate server-side.
    private let editUnsendWindow: TimeInterval = 15 * 60

    public init(
        users: [UserDTO] = UserFixtures.seed,
        conversations: [ConversationDTO] = ConversationFixtures.seed,
        messages: [String: [MessageDTO]] = MessageFixtures.seed,
        calls: [CallDTO] = CallFixtures.seed,
        mediaAssets: [MediaAssetDTO] = MediaAssetFixtures.seed,
        stories: [StoryDTO] = StoryFixtures.seed(expiryDuration: AppEnvironment.current.storyExpiryDuration),
        deviceContacts: [DeviceContactDTO] = DeviceContactFixtures.seed,
        channels: [ChannelDTO] = ChannelFixtures.seed,
        channelPosts: [String: [ChannelPostDTO]] = ChannelPostFixtures.seed,
        communities: [CommunityDTO] = CommunityFixtures.seed,
        wallets: [String: WalletDTO] = WalletFixtures.seed,
        paymentTransactions: [PaymentTransactionDTO] = PaymentTransactionFixtures.seed,
        bots: [BotDTO] = BotFixtures.seed
    ) {
        self.users = Dictionary(uniqueKeysWithValues: users.map { ($0.id, $0) })
        self.conversations = Dictionary(uniqueKeysWithValues: conversations.map { ($0.id, $0) })
        self.messagesByConversation = messages
        self.calls = calls
        self.mediaAssets = mediaAssets
        self.stories = stories
        self.deviceContacts = deviceContacts
        self.channels = Dictionary(uniqueKeysWithValues: channels.map { ($0.id, $0) })
        self.channelPosts = channelPosts
        self.communities = Dictionary(uniqueKeysWithValues: communities.map { ($0.id, $0) })
        self.wallets = wallets
        self.paymentTransactions = paymentTransactions
        self.bots = bots
        for messageList in messages.values {
            for message in messageList {
                for word in Self.tokenize(message.text) {
                    messageWordIndex[word, default: []].insert(message.id)
                }
            }
        }
    }

    private static func tokenize(_ text: String) -> [String] {
        text.lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
    }

    // MARK: - Users

    /// The single demo account this mock backend represents.
    public func currentUser() -> UserDTO {
        users[UserFixtures.currentUser.id] ?? UserFixtures.currentUser
    }

    public func user(id: String) -> UserDTO? {
        users[id]
    }

    public func allUsers() -> [UserDTO] {
        Array(users.values).sorted { $0.displayName < $1.displayName }
    }

    public func updateCurrentUserProfile(displayName: String, bio: String?, avatarURL: String?) -> UserDTO {
        let existing = currentUser()
        let updated = UserDTO(
            id: existing.id,
            displayName: displayName,
            handle: existing.handle,
            avatarURL: avatarURL ?? existing.avatarURL,
            status: existing.status,
            createdAt: existing.createdAt,
            bio: bio ?? existing.bio
        )
        users[updated.id] = updated
        return updated
    }

    // MARK: - Auth

    /// Challenges live five minutes and always accept `MockAuthConstants.demoOTPCode`.
    public func createOTPChallenge(phoneNumber: String) -> OTPChallengeDTO {
        let id = UUID().uuidString
        let expiresAt = Date().addingTimeInterval(300)
        otpChallenges[id] = (phoneNumber, MockAuthConstants.demoOTPCode, expiresAt)
        return OTPChallengeDTO(id: id, phoneNumber: phoneNumber, expiresAt: ISO8601Formatting.string(from: expiresAt))
    }

    public func resendOTPChallenge(id: String) -> OTPChallengeDTO? {
        guard let existing = otpChallenges[id] else { return nil }
        let expiresAt = Date().addingTimeInterval(300)
        otpChallenges[id] = (existing.phoneNumber, existing.code, expiresAt)
        return OTPChallengeDTO(id: id, phoneNumber: existing.phoneNumber, expiresAt: ISO8601Formatting.string(from: expiresAt))
    }

    /// A correct code consumes the challenge; a wrong or expired one returns false.
    public func verifyOTPChallenge(id: String, code: String) -> Bool {
        guard let challenge = otpChallenges[id], challenge.expiresAt > Date() else { return false }
        let isValid = challenge.code == code
        if isValid { otpChallenges[id] = nil }
        return isValid
    }

    public func setAppLockPIN(_ pin: String?) {
        appLockPIN = pin
    }

    public func isAppLockEnabled() -> Bool {
        appLockPIN != nil
    }

    public func verifyAppLockPIN(_ pin: String) -> Bool {
        appLockPIN != nil && appLockPIN == pin
    }

    // MARK: - Conversations

    public func allConversations() -> [ConversationDTO] {
        conversations.values.sorted { $0.updatedAt > $1.updatedAt }
    }

    public func conversation(id: String) -> ConversationDTO? {
        conversations[id]
    }

    public func updateConversationSettings(conversationId: String, readReceiptsEnabled: Bool, disappearingSeconds: Int?) -> ConversationDTO? {
        guard let existing = conversations[conversationId] else { return nil }
        let updated = existing.with(readReceiptsEnabled: readReceiptsEnabled, disappearingSeconds: .some(disappearingSeconds))
        conversations[conversationId] = updated
        return updated
    }

    public func setMuted(conversationId: String, muted: Bool) -> ConversationDTO? {
        guard let existing = conversations[conversationId] else { return nil }
        let updated = existing.with(isMuted: muted)
        conversations[conversationId] = updated
        return updated
    }

    public func setNotificationSound(conversationId: String, sound: String) -> ConversationDTO? {
        guard let existing = conversations[conversationId] else { return nil }
        let updated = existing.with(notificationSound: sound)
        conversations[conversationId] = updated
        return updated
    }

    public func setWallpaper(conversationId: String, wallpaper: String) -> ConversationDTO? {
        guard let existing = conversations[conversationId] else { return nil }
        let updated = existing.with(wallpaper: wallpaper)
        conversations[conversationId] = updated
        return updated
    }

    public func setPinnedMessage(conversationId: String, actingUserId: String, messageId: String?) -> ConversationDTO? {
        guard let existing = conversations[conversationId] else { return nil }
        if existing.kind == "group" {
            guard isAdminOrOwner(actingUserId, in: existing) else { return nil }
        }
        let updated = existing.with(pinnedMessageId: .some(messageId))
        conversations[conversationId] = updated
        return updated
    }

    // MARK: - Groups

    public func createGroup(title: String, description: String?, ownerId: String, memberIds: [String]) -> ConversationDTO {
        let id = UUID().uuidString
        var roster = [GroupMemberDTO(userId: ownerId, role: "owner")]
        roster.append(contentsOf: memberIds.filter { $0 != ownerId }.map { GroupMemberDTO(userId: $0, role: "member") })
        let conversation = ConversationDTO(
            id: id,
            kind: "group",
            title: title,
            participantIds: roster.map(\.userId),
            lastMessagePreview: nil,
            updatedAt: ISO8601Formatting.string(from: Date()),
            members: roster,
            groupDescription: description
        )
        conversations[id] = conversation
        messagesByConversation[id] = []
        return conversation
    }

    public func addMember(conversationId: String, actingUserId: String, newUserId: String) -> ConversationDTO? {
        guard let existing = conversations[conversationId], existing.kind == "group" else { return nil }
        guard isAdminOrOwner(actingUserId, in: existing) else { return nil }
        guard !existing.members.contains(where: { $0.userId == newUserId }) else { return existing }
        let roster = existing.members + [GroupMemberDTO(userId: newUserId, role: "member")]
        let updated = existing.with(participantIds: roster.map(\.userId), members: roster)
        conversations[conversationId] = updated
        return updated
    }

    public func removeMember(conversationId: String, actingUserId: String, targetUserId: String) -> ConversationDTO? {
        guard let existing = conversations[conversationId], existing.kind == "group" else { return nil }
        let isSelfLeave = actingUserId == targetUserId
        guard isSelfLeave || isAdminOrOwner(actingUserId, in: existing) else { return nil }
        guard existing.members.first(where: { $0.userId == targetUserId })?.role != "owner" else { return nil }
        let roster = existing.members.filter { $0.userId != targetUserId }
        let updated = existing.with(participantIds: roster.map(\.userId), members: roster)
        conversations[conversationId] = updated
        return updated
    }

    public func updateMemberRole(conversationId: String, actingUserId: String, targetUserId: String, role: String) -> ConversationDTO? {
        guard let existing = conversations[conversationId], existing.kind == "group" else { return nil }
        guard isAdminOrOwner(actingUserId, in: existing) else { return nil }
        guard existing.members.first(where: { $0.userId == targetUserId })?.role != "owner", role != "owner" else { return nil }
        guard let idx = existing.members.firstIndex(where: { $0.userId == targetUserId }) else { return nil }
        var roster = existing.members
        roster[idx] = GroupMemberDTO(userId: targetUserId, role: role)
        let updated = existing.with(members: roster)
        conversations[conversationId] = updated
        return updated
    }

    public func updateGroupInfo(conversationId: String, actingUserId: String, title: String, description: String?) -> ConversationDTO? {
        guard let existing = conversations[conversationId], existing.kind == "group" else { return nil }
        guard isAdminOrOwner(actingUserId, in: existing) else { return nil }
        let updated = existing.with(title: title, groupDescription: .some(description))
        conversations[conversationId] = updated
        return updated
    }

    private func isAdminOrOwner(_ userId: String, in conversation: ConversationDTO) -> Bool {
        let role = conversation.members.first { $0.userId == userId }?.role
        return role == "admin" || role == "owner"
    }

    // MARK: - Messages

    /// Cursor paging over the stored order: the cursor is the id of the last message of the previous page, and an unknown cursor restarts from the beginning. Expired disappearing messages are filtered out here.
    public func messagesPage(conversationId: String, cursor: String?, pageSize: Int) -> (items: [MessageDTO], nextCursor: String?, hasMore: Bool) {
        let now = Date()
        let all = (messagesByConversation[conversationId] ?? []).filter { message in
            guard let expiresAt = message.expiresAt, let expiryDate = ISO8601Formatting.date(from: expiresAt) else { return true }
            return expiryDate > now
        }
        let startIndex: Int
        if let cursor, let cursorIndex = all.firstIndex(where: { $0.id == cursor }) {
            startIndex = cursorIndex + 1
        } else {
            startIndex = 0
        }
        guard startIndex < all.count else {
            return ([], nil, false)
        }
        let endIndex = min(startIndex + pageSize, all.count)
        let slice = Array(all[startIndex..<endIndex])
        let hasMore = endIndex < all.count
        return (slice, hasMore ? slice.last?.id : nil, hasMore)
    }

    public func message(conversationId: String, messageId: String) -> MessageDTO? {
        messagesByConversation[conversationId]?.first { $0.id == messageId }
    }

    /// Also updates the word index and the conversation's last-message preview (prefixed with the sender's name in groups).
    public func appendMessage(_ message: MessageDTO) {
        messagesByConversation[message.conversationId, default: []].append(message)
        for word in Self.tokenize(message.text) {
            messageWordIndex[word, default: []].insert(message.id)
        }
        guard let conversation = conversations[message.conversationId] else { return }
        let base = previewText(for: message)
        let previewText: String
        if !message.isDeleted, conversation.kind == "group", let sender = users[message.senderId] {
            previewText = "\(sender.displayName): \(base)"
        } else {
            previewText = base
        }
        conversations[message.conversationId] = conversation.with(lastMessagePreview: .some(previewText), updatedAt: message.createdAt)
    }

    private func previewText(for message: MessageDTO) -> String {
        if message.isDeleted { return "This message was deleted" }
        guard let attachment = message.attachment else { return message.text }
        let label: String
        switch attachment.kind {
        case "image": label = "📷 Photo"
        case "video": label = "🎥 Video"
        default: label = "📄 \(attachment.fileName)"
        }
        return message.text.isEmpty ? label : "\(label): \(message.text)"
    }

    /// Creates a "sent" message; `expiresAt` is set when the conversation has disappearing messages turned on.
    public func createMessage(conversationId: String, senderId: String, text: String, replyToMessageId: String?, attachment: MediaAttachmentDTO? = nil, paymentTransactionId: String? = nil) -> MessageDTO {
        let id = UUID().uuidString
        let now = Date()
        let expiresAt: String?
        if let seconds = conversations[conversationId]?.disappearingSeconds, seconds > 0 {
            expiresAt = ISO8601Formatting.string(from: now.addingTimeInterval(TimeInterval(seconds)))
        } else {
            expiresAt = nil
        }
        let message = MessageDTO(
            id: id,
            conversationId: conversationId,
            senderId: senderId,
            text: text,
            createdAt: ISO8601Formatting.string(from: now),
            replyToMessageId: replyToMessageId,
            deliveryState: "sent",
            isDeleted: false,
            expiresAt: expiresAt,
            attachment: attachment,
            paymentTransactionId: paymentTransactionId
        )
        appendMessage(message)
        return message
    }

    public func editMessageText(conversationId: String, messageId: String, newText: String) -> MessageDTO? {
        guard var list = messagesByConversation[conversationId],
              let idx = list.firstIndex(where: { $0.id == messageId }),
              isWithinEditWindow(list[idx]) else {
            return nil
        }
        let message = list[idx]
        for word in Self.tokenize(message.text) {
            messageWordIndex[word]?.remove(messageId)
        }
        let updated = MessageDTO(
            id: message.id,
            conversationId: message.conversationId,
            senderId: message.senderId,
            text: newText,
            createdAt: message.createdAt,
            editedAt: ISO8601Formatting.string(from: Date()),
            replyToMessageId: message.replyToMessageId,
            deliveryState: message.deliveryState,
            isDeleted: false,
            expiresAt: message.expiresAt,
            attachment: message.attachment,
            reactions: message.reactions,
            paymentTransactionId: message.paymentTransactionId
        )
        list[idx] = updated
        messagesByConversation[conversationId] = list
        for word in Self.tokenize(newText) {
            messageWordIndex[word, default: []].insert(messageId)
        }
        return updated
    }

    /// Leaves a tombstone (`isDeleted`, empty text) instead of removing the message, within the edit window only.
    public func deleteMessage(conversationId: String, messageId: String) -> Bool {
        guard var list = messagesByConversation[conversationId],
              let idx = list.firstIndex(where: { $0.id == messageId }),
              isWithinEditWindow(list[idx]) else {
            return false
        }
        let message = list[idx]
        let updated = MessageDTO(
            id: message.id,
            conversationId: message.conversationId,
            senderId: message.senderId,
            text: "",
            createdAt: message.createdAt,
            editedAt: message.editedAt,
            replyToMessageId: message.replyToMessageId,
            deliveryState: message.deliveryState,
            isDeleted: true,
            expiresAt: message.expiresAt,
            attachment: message.attachment
        )
        list[idx] = updated
        messagesByConversation[conversationId] = list
        return true
    }

    public func transitionDelivery(conversationId: String, messageId: String, to state: String) -> MessageDTO? {
        guard var list = messagesByConversation[conversationId],
              let idx = list.firstIndex(where: { $0.id == messageId }) else {
            return nil
        }
        let message = list[idx]
        let updated = MessageDTO(
            id: message.id,
            conversationId: message.conversationId,
            senderId: message.senderId,
            text: message.text,
            createdAt: message.createdAt,
            editedAt: message.editedAt,
            replyToMessageId: message.replyToMessageId,
            deliveryState: state,
            isDeleted: message.isDeleted,
            expiresAt: message.expiresAt,
            attachment: message.attachment,
            reactions: message.reactions,
            paymentTransactionId: message.paymentTransactionId
        )
        list[idx] = updated
        messagesByConversation[conversationId] = list
        return updated
    }

    private func isWithinEditWindow(_ message: MessageDTO) -> Bool {
        guard !message.isDeleted, let created = ISO8601Formatting.date(from: message.createdAt) else { return false }
        return Date().timeIntervalSince(created) <= editUnsendWindow
    }

    /// Toggles `userId`'s own reaction with `emoji` — leaves any other emoji they've
    /// already reacted with on this message untouched (Discord-style, not one-per-user).
    public func toggleReaction(conversationId: String, messageId: String, userId: String, emoji: String) -> MessageDTO? {
        guard var list = messagesByConversation[conversationId],
              let idx = list.firstIndex(where: { $0.id == messageId }) else {
            return nil
        }
        let message = list[idx]
        var reactions = message.reactions
        if let ridx = reactions.firstIndex(where: { $0.emoji == emoji }) {
            var userIds = reactions[ridx].userIds
            if let uidx = userIds.firstIndex(of: userId) {
                userIds.remove(at: uidx)
            } else {
                userIds.append(userId)
            }
            if userIds.isEmpty {
                reactions.remove(at: ridx)
            } else {
                reactions[ridx] = ReactionDTO(emoji: emoji, userIds: userIds)
            }
        } else {
            reactions.append(ReactionDTO(emoji: emoji, userIds: [userId]))
        }
        let updated = MessageDTO(
            id: message.id,
            conversationId: message.conversationId,
            senderId: message.senderId,
            text: message.text,
            createdAt: message.createdAt,
            editedAt: message.editedAt,
            replyToMessageId: message.replyToMessageId,
            deliveryState: message.deliveryState,
            isDeleted: message.isDeleted,
            expiresAt: message.expiresAt,
            attachment: message.attachment,
            reactions: reactions,
            paymentTransactionId: message.paymentTransactionId
        )
        list[idx] = updated
        messagesByConversation[conversationId] = list
        return updated
    }

    // MARK: - Calls

    public func allCalls() -> [CallDTO] {
        calls.sorted { $0.startedAt > $1.startedAt }
    }

    public func createCall(conversationId: String, counterpartId: String, type: String, direction: String) -> CallDTO {
        let call = CallDTO(
            id: UUID().uuidString,
            conversationId: conversationId,
            counterpartId: counterpartId,
            type: type,
            direction: direction,
            outcome: "ringing",
            startedAt: ISO8601Formatting.string(from: Date())
        )
        calls.append(call)
        return call
    }

    public func updateCallOutcome(callId: String, outcome: String, duration: Double) -> CallDTO? {
        guard let idx = calls.firstIndex(where: { $0.id == callId }) else { return nil }
        let existing = calls[idx]
        let updated = CallDTO(
            id: existing.id,
            conversationId: existing.conversationId,
            counterpartId: existing.counterpartId,
            type: existing.type,
            direction: existing.direction,
            outcome: outcome,
            startedAt: existing.startedAt,
            duration: duration
        )
        calls[idx] = updated
        return updated
    }

    // MARK: - Media

    public func allMediaAssets() -> [MediaAssetDTO] {
        mediaAssets
    }

    public func mediaMessages(conversationId: String) -> [MessageDTO] {
        let now = Date()
        return (messagesByConversation[conversationId] ?? []).filter { message in
            guard message.attachment != nil, !message.isDeleted else { return false }
            if let expiresAt = message.expiresAt, let expiryDate = ISO8601Formatting.date(from: expiresAt), expiryDate <= now {
                return false
            }
            return true
        }
    }

    /// Simulates compression by shrinking non-file media to 22% of the original size when `quality` is "compressed"; view-once never applies to plain files.
    public func createMediaMessage(conversationId: String, senderId: String, assetId: String, quality: String, caption: String, isViewOnce: Bool) -> MessageDTO? {
        guard let asset = mediaAssets.first(where: { $0.id == assetId }) else { return nil }
        let finalSize: Int
        if asset.kind == "file" {
            finalSize = asset.originalSizeBytes
        } else {
            finalSize = quality == "compressed" ? Int(Double(asset.originalSizeBytes) * 0.22) : asset.originalSizeBytes
        }
        let attachment = MediaAttachmentDTO(
            id: UUID().uuidString,
            kind: asset.kind,
            fileName: asset.fileName,
            sizeBytes: finalSize,
            quality: quality,
            url: asset.thumbnailURL,
            durationSeconds: asset.durationSeconds,
            isViewOnce: asset.kind != "file" && isViewOnce
        )
        return createMessage(conversationId: conversationId, senderId: senderId, text: caption, replyToMessageId: nil, attachment: attachment)
    }

    /// Marks a view-once attachment as opened. Idempotent: an already-consumed or non-view-once message is returned unchanged.
    public func consumeViewOnceAttachment(conversationId: String, messageId: String) -> MessageDTO? {
        guard var list = messagesByConversation[conversationId],
              let idx = list.firstIndex(where: { $0.id == messageId }),
              let attachment = list[idx].attachment,
              attachment.isViewOnce, !attachment.isConsumed else {
            return messagesByConversation[conversationId]?.first { $0.id == messageId }
        }
        let message = list[idx]
        let updated = MessageDTO(
            id: message.id,
            conversationId: message.conversationId,
            senderId: message.senderId,
            text: message.text,
            createdAt: message.createdAt,
            editedAt: message.editedAt,
            replyToMessageId: message.replyToMessageId,
            deliveryState: message.deliveryState,
            isDeleted: message.isDeleted,
            expiresAt: message.expiresAt,
            attachment: attachment.consumed(),
            reactions: message.reactions,
            paymentTransactionId: message.paymentTransactionId
        )
        list[idx] = updated
        messagesByConversation[conversationId] = list
        return updated
    }

    public func mediaAsset(id: String) -> MediaAssetDTO? {
        mediaAssets.first { $0.id == id }
    }

    // MARK: - Stories

    /// Stories the viewer may see: unexpired or highlighted, filtered by `privacy` ("onlyMe", "closeFriends"), oldest first. The author always sees their own.
    public func activeStories(viewerId: String) -> [StoryDTO] {
        let now = Date()
        return stories.filter { story in
            let isActive = story.isHighlighted || (ISO8601Formatting.date(from: story.expiresAt).map { $0 > now } ?? false)
            guard isActive else { return false }
            if story.authorId == viewerId { return true }
            switch story.privacy {
            case "onlyMe": return false
            case "closeFriends": return closeFriendIds.contains(viewerId)
            default: return true
            }
        }.sorted { $0.createdAt < $1.createdAt }
    }

    public func highlights(authorId: String) -> [StoryDTO] {
        stories.filter { $0.authorId == authorId && $0.isHighlighted }.sorted { $0.createdAt > $1.createdAt }
    }

    public func story(id: String) -> StoryDTO? {
        stories.first { $0.id == id }
    }

    public func createStory(
        authorId: String,
        backgroundColorHex: String?,
        mediaURL: String?,
        overlayText: String?,
        overlayEmoji: String?,
        privacy: String,
        notifyOnScreenshot: Bool,
        expiryDuration: TimeInterval
    ) -> StoryDTO {
        let now = Date()
        let story = StoryDTO(
            id: UUID().uuidString,
            authorId: authorId,
            createdAt: ISO8601Formatting.string(from: now),
            expiresAt: ISO8601Formatting.string(from: now.addingTimeInterval(expiryDuration)),
            backgroundColorHex: backgroundColorHex,
            mediaURL: mediaURL,
            overlayText: overlayText,
            overlayEmoji: overlayEmoji,
            privacy: privacy,
            notifyOnScreenshot: notifyOnScreenshot
        )
        stories.append(story)
        return story
    }

    /// Ignores the author's own views and repeat views.
    public func markStoryViewed(storyId: String, viewerId: String) {
        guard let idx = stories.firstIndex(where: { $0.id == storyId }) else { return }
        let existing = stories[idx]
        guard existing.authorId != viewerId, !existing.viewerIds.contains(viewerId) else { return }
        stories[idx] = existing.with(viewerIds: existing.viewerIds + [viewerId])
    }

    public func setStoryHighlighted(storyId: String, isHighlighted: Bool) -> StoryDTO? {
        guard let idx = stories.firstIndex(where: { $0.id == storyId }) else { return nil }
        let updated = stories[idx].with(isHighlighted: isHighlighted)
        stories[idx] = updated
        return updated
    }

    public func deleteStory(storyId: String) {
        stories.removeAll { $0.id == storyId }
    }

    public func closeFriends() -> [String] {
        closeFriendIds
    }

    public func setCloseFriends(_ userIds: [String]) {
        closeFriendIds = userIds
    }

    // MARK: - Contacts / Discovery

    public func allDeviceContacts() -> [DeviceContactDTO] {
        deviceContacts
    }

    /// Case-insensitive match on display name or handle; a blank query returns nothing.
    public func searchUsers(query: String, excluding userId: String) -> [UserDTO] {
        let lowered = query.trimmingCharacters(in: .whitespaces).lowercased()
        guard !lowered.isEmpty else { return [] }
        return users.values
            .filter { $0.id != userId && ($0.displayName.lowercased().contains(lowered) || $0.handle.lowercased().contains(lowered)) }
            .sorted { $0.displayName < $1.displayName }
    }

    /// Improve: throttled from the start — at most `requestThrottleLimit` requests per
    /// rolling `requestThrottleWindow`, exactly like a real API would rate-limit spam.
    public func sendContactRequest(fromUserId: String, toUserId: String) -> ContactRequestDTO? {
        let now = Date()
        sentRequestTimestamps.removeAll { now.timeIntervalSince($0) > requestThrottleWindow }
        guard sentRequestTimestamps.count < requestThrottleLimit else { return nil }
        sentRequestTimestamps.append(now)
        let request = ContactRequestDTO(id: UUID().uuidString, fromUserId: fromUserId, toUserId: toUserId, status: "pending", createdAt: ISO8601Formatting.string(from: now))
        contactRequests.append(request)
        return request
    }

    public func incomingRequests(for userId: String) -> [ContactRequestDTO] {
        contactRequests
            .filter { $0.toUserId == userId && $0.status == "pending" }
            .sorted { $0.createdAt > $1.createdAt }
    }

    /// Accepting records the other party of the request as a connection.
    public func respondToRequest(requestId: String, actingUserId: String, accept: Bool) -> ContactRequestDTO? {
        guard let idx = contactRequests.firstIndex(where: { $0.id == requestId }) else { return nil }
        let existing = contactRequests[idx]
        let updated = ContactRequestDTO(id: existing.id, fromUserId: existing.fromUserId, toUserId: existing.toUserId, status: accept ? "accepted" : "declined", createdAt: existing.createdAt)
        contactRequests[idx] = updated
        if accept {
            let counterpart = existing.fromUserId == actingUserId ? existing.toUserId : existing.fromUserId
            connections.insert(counterpart)
        }
        return updated
    }

    public func myConnections() -> [String] {
        Array(connections)
    }

    public func discoverability() -> String {
        discoverabilitySetting
    }

    public func setDiscoverability(_ value: String) {
        discoverabilitySetting = value
    }

    /// QR add-friend connects instantly — no pending/accept step, since scanning in person
    /// already implies mutual consent (unlike a search-based request to a stranger).
    public func connectViaQR(currentUserId: String, scannedUserId: String) -> Bool {
        guard scannedUserId != currentUserId else { return false }
        connections.insert(scannedUserId)
        return true
    }

    /// Demo hook: a pending request from a random user who is not yet connected. Returns nil when there is none or one is already pending.
    public func simulateIncomingRequest(toUserId: String) -> ContactRequestDTO? {
        let candidates = users.keys.filter { $0 != toUserId && !connections.contains($0) }
        guard let senderId = candidates.randomElement() else { return nil }
        guard !contactRequests.contains(where: { $0.fromUserId == senderId && $0.toUserId == toUserId && $0.status == "pending" }) else {
            return nil
        }
        let request = ContactRequestDTO(id: UUID().uuidString, fromUserId: senderId, toUserId: toUserId, status: "pending", createdAt: ISO8601Formatting.string(from: Date()))
        contactRequests.append(request)
        return request
    }

    /// Reuses the existing direct conversation with this user if there is one.
    public func findOrCreateDirectConversation(currentUserId: String, otherUserId: String) -> ConversationDTO {
        if let existing = conversations.values.first(where: { $0.kind == "direct" && Set($0.participantIds) == Set([currentUserId, otherUserId]) }) {
            return existing
        }
        let id = UUID().uuidString
        let conversation = ConversationDTO(
            id: id,
            kind: "direct",
            title: users[otherUserId]?.displayName ?? "Unknown",
            participantIds: [currentUserId, otherUserId],
            lastMessagePreview: nil,
            updatedAt: ISO8601Formatting.string(from: Date())
        )
        conversations[id] = conversation
        messagesByConversation[id] = []
        return conversation
    }

    /// Demo affordance for Module 8: fires several messages from different group members
    /// in one shot, so notification bundling/digest behavior has a burst to bundle.
    public func simulateGroupActivity(conversationId: String, currentUserId: String) -> [MessageDTO] {
        guard let conversation = conversations[conversationId], conversation.kind == "group" else { return [] }
        let others = conversation.members.map(\.userId).filter { $0 != currentUserId }
        guard !others.isEmpty else { return [] }
        let picks = Array(others.shuffled().prefix(min(3, others.count)))
        return picks.map { senderId in
            createMessage(conversationId: conversationId, senderId: senderId, text: CannedReplies.random(), replyToMessageId: nil)
        }
    }

    // MARK: - Privacy & Security

    public func lastSeenVisibility() -> String {
        lastSeenVisibilitySetting
    }

    public func setLastSeenVisibility(_ value: String) {
        lastSeenVisibilitySetting = value
    }

    public func blockedUserIds() -> [String] {
        Array(blockedUserIdSet)
    }

    public func isUserBlocked(_ userId: String) -> Bool {
        blockedUserIdSet.contains(userId)
    }

    public func blockUser(_ userId: String) {
        blockedUserIdSet.insert(userId)
    }

    public func unblockUser(_ userId: String) {
        blockedUserIdSet.remove(userId)
    }

    public func addReport(reportedUserId: String, reason: String) {
        reports.append(ReportDTO(id: UUID().uuidString, reportedUserId: reportedUserId, reason: reason, createdAt: ISO8601Formatting.string(from: Date())))
    }

    // MARK: - Channels

    public func allChannels() -> [ChannelDTO] {
        Array(channels.values).sorted { $0.title < $1.title }
    }

    public func myChannels(userId: String) -> [ChannelDTO] {
        allChannels().filter { $0.ownerId == userId || $0.adminIds.contains(userId) || $0.followerIds.contains(userId) }
    }

    public func channel(id: String) -> ChannelDTO? {
        channels[id]
    }

    public func createChannel(title: String, description: String?, ownerId: String) -> ChannelDTO {
        let channel = ChannelDTO(
            id: "ch-\(UUID().uuidString.prefix(8))",
            title: title,
            description: description,
            ownerId: ownerId,
            followerIds: [ownerId],
            createdAt: ISO8601Formatting.string(from: Date())
        )
        channels[channel.id] = channel
        return channel
    }

    public func followChannel(channelId: String, userId: String) -> ChannelDTO? {
        guard let existing = channels[channelId] else { return nil }
        var followers = Set(existing.followerIds)
        followers.insert(userId)
        let updated = existing.with(followerIds: Array(followers))
        channels[channelId] = updated
        return updated
    }

    public func unfollowChannel(channelId: String, userId: String) -> ChannelDTO? {
        guard let existing = channels[channelId] else { return nil }
        var followers = Set(existing.followerIds)
        followers.remove(userId)
        let updated = existing.with(followerIds: Array(followers))
        channels[channelId] = updated
        return updated
    }

    public func channelPosts(channelId: String) -> [ChannelPostDTO] {
        (channelPosts[channelId] ?? []).sorted { $0.createdAt > $1.createdAt }
    }

    /// Returns `nil` when `authorId` isn't an owner/admin — enforced server-side, not
    /// just hidden from the composer client-side.
    public func createChannelPost(channelId: String, authorId: String, text: String) -> ChannelPostDTO? {
        guard let channel = channels[channelId], channel.ownerId == authorId || channel.adminIds.contains(authorId) else {
            return nil
        }
        let post = ChannelPostDTO(
            id: "chp-\(UUID().uuidString.prefix(8))",
            channelId: channelId,
            authorId: authorId,
            text: text,
            createdAt: ISO8601Formatting.string(from: Date())
        )
        channelPosts[channelId, default: []].append(post)
        return post
    }

    public func registerPostView(channelId: String, postId: String, viewerId: String) -> ChannelPostDTO? {
        guard let posts = channelPosts[channelId], let index = posts.firstIndex(where: { $0.id == postId }) else { return nil }
        var viewers = Set(posts[index].viewerIds)
        viewers.insert(viewerId)
        let updated = posts[index].with(viewerIds: Array(viewers))
        channelPosts[channelId]?[index] = updated
        return updated
    }

    // MARK: - Communities

    public func allCommunities() -> [CommunityDTO] {
        Array(communities.values).sorted { $0.title < $1.title }
    }

    public func community(id: String) -> CommunityDTO? {
        communities[id]
    }

    public func createCommunity(title: String, description: String?, ownerId: String) -> CommunityDTO {
        let community = CommunityDTO(
            id: "com-\(UUID().uuidString.prefix(8))",
            title: title,
            description: description,
            ownerId: ownerId,
            memberIds: [ownerId],
            createdAt: ISO8601Formatting.string(from: Date())
        )
        communities[community.id] = community
        return community
    }

    public func linkGroup(communityId: String, conversationId: String) -> CommunityDTO? {
        guard let community = communities[communityId], let conversation = conversations[conversationId] else { return nil }
        guard !community.linkedItems.contains(where: { $0.itemId == conversationId }) else { return community }
        let item = CommunityLinkedItemDTO(itemId: conversationId, kind: "group", title: conversation.title)
        let updated = community.with(linkedItems: community.linkedItems + [item])
        communities[communityId] = updated
        return updated
    }

    public func linkChannel(communityId: String, channelId: String) -> CommunityDTO? {
        guard let community = communities[communityId], let channel = channels[channelId] else { return nil }
        guard !community.linkedItems.contains(where: { $0.itemId == channelId }) else { return community }
        let item = CommunityLinkedItemDTO(itemId: channelId, kind: "channel", title: channel.title)
        let updated = community.with(linkedItems: community.linkedItems + [item])
        communities[communityId] = updated
        return updated
    }

    // MARK: - Search

    public func searchConversationsByTitle(_ text: String) -> [ConversationDTO] {
        guard !text.isEmpty else { return [] }
        let lower = text.lowercased()
        return conversations.values.filter { $0.title.lowercased().contains(lower) }
            .sorted { $0.updatedAt > $1.updatedAt }
    }

    public func searchUsers(_ text: String) -> [UserDTO] {
        guard !text.isEmpty else { return [] }
        let lower = text.lowercased()
        return allUsers().filter { $0.displayName.lowercased().contains(lower) || $0.handle.lowercased().contains(lower) }
    }

    /// `conversationId == nil` searches across every conversation (global search);
    /// otherwise scoped to one thread's in-chat search.
    public func searchMessages(
        conversationId: String?,
        text: String,
        senderId: String?,
        hasMediaOnly: Bool,
        after: String?,
        before: String?
    ) -> [MessageDTO] {
        let words = Self.tokenize(text)
        var matchingIds: Set<String>?
        if !words.isEmpty {
            var result: Set<String>?
            for word in words {
                let ids = messageWordIndex[word] ?? []
                result = result.map { $0.intersection(ids) } ?? ids
            }
            matchingIds = result ?? []
        }
        let afterDate = after.flatMap(ISO8601Formatting.date(from:))
        let beforeDate = before.flatMap(ISO8601Formatting.date(from:))

        let pool: [MessageDTO]
        if let conversationId {
            pool = messagesByConversation[conversationId] ?? []
        } else {
            pool = messagesByConversation.values.flatMap { $0 }
        }

        return pool.filter { message in
            guard !message.isDeleted else { return false }
            if let matchingIds, !matchingIds.contains(message.id) { return false }
            if let senderId, message.senderId != senderId { return false }
            if hasMediaOnly, message.attachment == nil { return false }
            guard let createdAt = ISO8601Formatting.date(from: message.createdAt) else { return true }
            if let afterDate, createdAt < afterDate { return false }
            if let beforeDate, createdAt > beforeDate { return false }
            return true
        }.sorted { $0.createdAt > $1.createdAt }
    }

    // MARK: - Payments

    public func wallet(for userId: String) -> WalletDTO {
        wallets[userId] ?? WalletDTO(balance: 0, kycStatus: "notStarted")
    }

    public func submitKYC(userId: String, fullName: String, country: String) -> WalletDTO {
        let existing = wallet(for: userId)
        let updated = WalletDTO(balance: existing.balance, kycStatus: "verified", kycFullName: fullName, kycCountry: country)
        wallets[userId] = updated
        return updated
    }

    public func topUp(userId: String, amount: Double) -> WalletDTO {
        let existing = wallet(for: userId)
        let updated = WalletDTO(balance: existing.balance + amount, kycStatus: existing.kycStatus, kycFullName: existing.kycFullName, kycCountry: existing.kycCountry)
        wallets[userId] = updated
        return updated
    }

    public func paymentTransactions(for userId: String) -> [PaymentTransactionDTO] {
        paymentTransactions.filter { $0.fromUserId == userId || $0.toUserId == userId }
            .sorted { $0.createdAt > $1.createdAt }
    }

    /// Returns `nil` on insufficient balance or unverified KYC — the route maps that
    /// to a specific, user-facing error rather than a generic failure.
    public func sendMoney(fromUserId: String, toUserId: String, amount: Double, note: String?, conversationId: String?) -> PaymentTransactionDTO? {
        let sender = wallet(for: fromUserId)
        guard sender.kycStatus == "verified", amount > 0, sender.balance >= amount else { return nil }
        wallets[fromUserId] = WalletDTO(balance: sender.balance - amount, kycStatus: sender.kycStatus, kycFullName: sender.kycFullName, kycCountry: sender.kycCountry)
        let recipient = wallet(for: toUserId)
        wallets[toUserId] = WalletDTO(balance: recipient.balance + amount, kycStatus: recipient.kycStatus, kycFullName: recipient.kycFullName, kycCountry: recipient.kycCountry)

        let transaction = PaymentTransactionDTO(
            id: "pay-\(UUID().uuidString.prefix(8))",
            fromUserId: fromUserId,
            toUserId: toUserId,
            amount: amount,
            note: note,
            kind: "send",
            status: "completed",
            conversationId: conversationId,
            createdAt: ISO8601Formatting.string(from: Date())
        )
        paymentTransactions.append(transaction)
        if let conversationId {
            let noteSuffix = note.map { " · \($0)" } ?? ""
            _ = createMessage(
                conversationId: conversationId,
                senderId: fromUserId,
                text: "💸 Sent \(Self.formattedAmount(amount))\(noteSuffix)",
                replyToMessageId: nil,
                paymentTransactionId: transaction.id
            )
        }
        return transaction
    }

    /// Creates a pending request; no money moves until it is accepted. If tied to a conversation, a payment message is posted there.
    public func requestMoney(fromUserId: String, toUserId: String, amount: Double, note: String?, conversationId: String?) -> PaymentTransactionDTO {
        let transaction = PaymentTransactionDTO(
            id: "pay-\(UUID().uuidString.prefix(8))",
            fromUserId: fromUserId,
            toUserId: toUserId,
            amount: amount,
            note: note,
            kind: "request",
            status: "pendingAcceptance",
            conversationId: conversationId,
            createdAt: ISO8601Formatting.string(from: Date())
        )
        paymentTransactions.append(transaction)
        if let conversationId {
            let noteSuffix = note.map { " · \($0)" } ?? ""
            _ = createMessage(
                conversationId: conversationId,
                senderId: fromUserId,
                text: "💰 Requested \(Self.formattedAmount(amount))\(noteSuffix)",
                replyToMessageId: nil,
                paymentTransactionId: transaction.id
            )
        }
        return transaction
    }

    /// `nil` covers both "not found" and "the payer can't afford / isn't verified" —
    /// the route already knows the acting user, so it can tell those apart if needed.
    public func respondToRequest(transactionId: String, accept: Bool) -> PaymentTransactionDTO? {
        guard let idx = paymentTransactions.firstIndex(where: { $0.id == transactionId }),
              paymentTransactions[idx].status == "pendingAcceptance" else {
            return nil
        }
        let transaction = paymentTransactions[idx]
        if accept {
            let payer = wallet(for: transaction.toUserId)
            guard payer.kycStatus == "verified", payer.balance >= transaction.amount else { return nil }
            wallets[transaction.toUserId] = WalletDTO(balance: payer.balance - transaction.amount, kycStatus: payer.kycStatus, kycFullName: payer.kycFullName, kycCountry: payer.kycCountry)
            let requester = wallet(for: transaction.fromUserId)
            wallets[transaction.fromUserId] = WalletDTO(balance: requester.balance + transaction.amount, kycStatus: requester.kycStatus, kycFullName: requester.kycFullName, kycCountry: requester.kycCountry)
        }
        let updated = transaction.with(status: accept ? "completed" : "declined")
        paymentTransactions[idx] = updated
        if let conversationId = transaction.conversationId {
            _ = createMessage(
                conversationId: conversationId,
                senderId: transaction.toUserId,
                text: accept ? "✅ Payment sent" : "❌ Request declined",
                replyToMessageId: nil,
                paymentTransactionId: transaction.id
            )
        }
        return updated
    }

    private static func formattedAmount(_ amount: Double) -> String {
        "$" + String(format: "%.2f", amount)
    }

    // MARK: - Bots

    public func allBots() -> [BotDTO] {
        bots
    }

    /// Bots are matched to users by identical id.
    public func bot(forUserId userId: String) -> BotDTO? {
        bots.first { $0.id == userId }
    }

    /// Latest message text from `senderId`, used to build a bot's reply.
    public func lastMessageText(conversationId: String, senderId: String) -> String? {
        (messagesByConversation[conversationId] ?? []).last { $0.senderId == senderId }?.text
    }
}
