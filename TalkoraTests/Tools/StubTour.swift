@testable import Talkora
import Foundation
@testable import Core
@testable import Mock

/// Calls every repository method once with seeded ids so each endpoint gets recorded.
/// Reads run first, then writes (which mutate the throwaway store).
///
/// Shared by `StubCatalogGeneratorTests` (records the responses) and `StubCoverageTests`
/// (asserts every call is answered by the stubbed backend). Add new repository methods here.
struct StubTour {
    let api: APIClientProtocol
    let environment: AppEnvironment

    func run() async {
        let users = UserRepository(api: api)
        let chat = ChatRepository(api: api)
        let auth = AuthRepository(api: api, environment: environment)
        let calls = CallRepository(api: api)
        let media = MediaRepository(api: api)
        let stories = StoryRepository(api: api)
        let contacts = ContactRepository(api: api)
        let privacy = PrivacyRepository(api: api)
        let channels = ChannelRepository(api: api, userRepository: users)
        let search = SearchRepository(api: api)
        let payments = PaymentRepository(api: api)
        let bots = BotRepository(api: api)

        // MARK: Reads

        let me = try? await users.currentUser()
        let allUsers = (try? await users.allUsers()) ?? []
        for user in allUsers { _ = try? await users.user(id: user.id) }
        let other = allUsers.first { $0.id != me?.id }
        let third = allUsers.first { $0.id != me?.id && $0.id != other?.id }

        let conversations = (try? await chat.conversations()) ?? []
        for conversation in conversations {
            _ = try? await chat.conversation(id: conversation.id)
            _ = try? await chat.messages(conversationId: conversation.id, cursor: nil)
            _ = try? await media.mediaHistory(conversationId: conversation.id)
        }
        let direct = conversations.first { $0.kind == .direct }
        let group = conversations.first { $0.kind == .group }

        _ = try? await calls.callHistory()
        let assets = (try? await media.availableAssets()) ?? []
        _ = try? await stories.activeStories()
        if let me { _ = try? await stories.highlights(authorId: me.id) }
        _ = try? await stories.closeFriendIds()
        _ = try? await contacts.syncDeviceContacts()
        _ = try? await contacts.searchUsers(query: "a")
        _ = try? await contacts.incomingRequests()
        _ = try? await contacts.myConnections()
        _ = try? await contacts.discoverability()
        _ = try? await privacy.lastSeenVisibility()
        _ = try? await privacy.blockedUsers()
        if let other { _ = try? await privacy.isBlocked(other.id) }
        _ = try? await bots.allBots()
        _ = try? await payments.wallet()
        _ = try? await payments.transactions()
        _ = try? await auth.isAppLockEnabled()

        let allChannels = (try? await channels.allChannels()) ?? []
        _ = try? await channels.myChannels()
        for channel in allChannels {
            _ = try? await channels.channel(id: channel.id)
            _ = try? await channels.posts(channelId: channel.id)
        }
        let allCommunities = (try? await channels.communities()) ?? []
        for community in allCommunities { _ = try? await channels.community(id: community.id) }

        _ = try? await search.globalSearch(query: "hello", filter: MessageSearchFilter())
        if let direct { _ = try? await search.searchMessages(conversationId: direct.id, query: "hello", filter: MessageSearchFilter()) }

        // MARK: Auth writes

        if let challenge = try? await auth.requestOTP(phoneNumber: "+8801712345678") {
            _ = try? await auth.resendOTP(challengeId: challenge.id)
            _ = try? await auth.verifyOTP(challengeId: challenge.id, code: MockAuthConstants.demoOTPCode)
        }
        _ = try? await auth.login(identifier: "demo", password: "demo")
        if let me { _ = try? await auth.completeProfile(userId: me.id, displayName: "Demo User") }
        _ = try? await auth.verifyAppLockPIN("1234")
        try? await auth.setAppLockPIN("1234")

        // MARK: Chat writes

        if let direct {
            if let message = try? await chat.sendMessage(text: "Hello", conversationId: direct.id, replyToMessageId: nil) {
                _ = try? await chat.editMessage(messageId: message.id, conversationId: direct.id, newText: "Hello!")
                _ = try? await chat.toggleReaction("👍", messageId: message.id, conversationId: direct.id)
                _ = try? await chat.setPinnedMessage(message.id, in: direct.id)
                _ = try? await chat.markViewOnceConsumed(messageId: message.id, conversationId: direct.id)
                _ = try? await chat.simulateDeliveryTicks(messageId: message.id, conversationId: direct.id)
                try? await chat.deleteMessage(messageId: message.id, conversationId: direct.id)
            }
            _ = try? await chat.simulateIncomingReply(conversationId: direct.id)
            _ = try? await chat.setMuted(true, for: direct.id)
            _ = try? await chat.setNotificationSound(.silent, for: direct.id)
            _ = try? await chat.setWallpaper(.ocean, for: direct.id)
            _ = try? await chat.updateSettings(conversationId: direct.id, readReceiptsEnabled: false, disappearingDuration: nil)
        }
        if let group { _ = try? await chat.simulateGroupActivity(conversationId: group.id) }
        if let other { _ = try? await chat.findOrCreateDirectConversation(with: other.id) }
        if let other, let third, let created = try? await chat.createGroup(title: "Weekend Plans", description: "Trip", memberIds: [other.id]) {
            _ = try? await chat.addMember(third.id, to: created.id)
            _ = try? await chat.updateMemberRole(third.id, role: .admin, in: created.id)
            _ = try? await chat.updateGroupInfo(conversationId: created.id, title: "Weekend Trip", description: "Updated")
            _ = try? await chat.removeMember(third.id, from: created.id)
        }

        // MARK: Other writes

        if let direct, let asset = assets.first {
            _ = try? await media.sendMedia(conversationId: direct.id, assetId: asset.id, quality: .compressed, caption: "Look", isViewOnce: false)
        }
        if let story = try? await stories.createStory(backgroundColorHex: "#336699", mediaAssetId: nil, overlayText: "Hi", overlayEmoji: nil, privacy: .everyone, notifyOnScreenshot: false) {
            try? await stories.markViewed(story.id)
            _ = try? await stories.viewers(of: story.id)
            _ = try? await stories.setHighlighted(story.id, isHighlighted: true)
            try? await stories.deleteStory(story.id)
        }
        if let other {
            try? await stories.setCloseFriends([other.id])
            _ = try? await contacts.sendContactRequest(to: other.id)
            _ = try? await contacts.connectViaQR(userId: other.id)
            try? await privacy.blockUser(other.id)
            try? await privacy.reportUser(other.id, reason: "spam")
            try? await privacy.unblockUser(other.id)
        }
        _ = try? await contacts.simulateIncomingRequest()
        if let request = (try? await contacts.incomingRequests())?.first {
            _ = try? await contacts.respondToRequest(request.id, accept: true)
        }
        _ = try? await contacts.setDiscoverability(.contactsOnly)
        _ = try? await privacy.setLastSeenVisibility(.nobody)

        if let direct, let other, let call = try? await calls.startCall(conversationId: direct.id, counterpartId: other.id, type: .voice, direction: .outgoing) {
            _ = try? await calls.endCall(call.id, outcome: .completed, duration: 30)
        }

        _ = try? await payments.submitKYC(fullName: "Demo User", country: "BD")
        _ = try? await payments.topUp(amount: 50)
        if let other {
            _ = try? await payments.sendMoney(to: other.id, amount: 5, note: "Lunch", conversationId: direct?.id)
            if let request = try? await payments.requestMoney(from: other.id, amount: 8, note: "Tickets", conversationId: direct?.id) {
                _ = try? await payments.respondToRequest(request.id, accept: true)
            }
        }

        if let channel = try? await channels.createChannel(title: "Daily News", description: "Updates") {
            _ = try? await channels.follow(channel.id)
            _ = try? await channels.unfollow(channel.id)
            if let post = try? await channels.createPost(channelId: channel.id, text: "First post") {
                _ = try? await channels.registerView(postId: post.id, channelId: channel.id)
            }
            if let community = try? await channels.createCommunity(title: "Neighbours", description: "Local") {
                _ = try? await channels.linkChannel(channel.id, toCommunity: community.id)
                if let group { _ = try? await channels.linkGroup(group.id, toCommunity: community.id) }
            }
        }
    }
}
