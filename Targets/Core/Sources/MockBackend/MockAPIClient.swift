import Foundation

/// Implements `APIClientProtocol` against `MockDataStore` instead of a real server.
/// Routes on `endpoint.path`/`method` exactly as a router would dispatch real HTTP requests,
/// then round-trips the result through `Codable` so every call site behaves as if it decoded
/// a real JSON response body — this is what keeps the mock layer swappable for `RealAPIClient`.
public final class MockAPIClient: APIClientProtocol {
    private let store: MockDataStore
    private let simulator: MockNetworkSimulator
    private let environment: AppEnvironment

    public init(store: MockDataStore = .shared, environment: AppEnvironment = .current) {
        self.store = store
        self.simulator = MockNetworkSimulator(environment: environment)
        self.environment = environment
    }

    /// Routes by method and path. Fixed paths are matched in the `switch`; anything with ids falls through to the `default` branch, which compares method and path segments in order. An unknown route throws `APIError.notFound`. Parameters are read from `endpoint.query`, which holds the flattened body.
    public func request<T: Decodable & Sendable>(_ endpoint: Endpoint) async throws -> T {
        try await simulator.simulateLatency()
        try simulator.maybeThrowInjectedError(for: endpoint)

        let segments = Self.pathSegments(endpoint.path)

        switch (endpoint.method, endpoint.path) {
        case (.get, "/me"):
            let user = await store.currentUser()
            return try Self.transcode(user)

        case (.get, "/conversations"):
            let conversations = await store.allConversations()
            return try Self.transcode(conversations)

        case (.post, "/auth/otp/request"):
            guard let phoneNumber = endpoint.query["phoneNumber"], !phoneNumber.isEmpty else {
                throw APIError.custom(message: "A phone number is required.", retryable: false)
            }
            let challenge = await store.createOTPChallenge(phoneNumber: phoneNumber)
            return try Self.transcode(challenge)

        case (.post, "/auth/otp/resend"):
            guard let challengeId = endpoint.query["challengeId"],
                  let challenge = await store.resendOTPChallenge(id: challengeId) else {
                throw APIError.notFound
            }
            return try Self.transcode(challenge)

        case (.post, "/auth/otp/verify"):
            guard let challengeId = endpoint.query["challengeId"], let code = endpoint.query["code"] else {
                throw APIError.notFound
            }
            guard await store.verifyOTPChallenge(id: challengeId, code: code) else {
                throw APIError.custom(message: "Invalid or expired code.", retryable: true)
            }
            let user = await store.currentUser()
            return try Self.transcode(user)

        case (.post, "/auth/login"):
            // Mock login accepts any non-empty credentials and always resolves to the
            // single demo account this mock backend represents.
            guard let identifier = endpoint.query["identifier"], !identifier.isEmpty,
                  let password = endpoint.query["password"], !password.isEmpty else {
                throw APIError.custom(message: "Invalid credentials.", retryable: true)
            }
            let user = await store.currentUser()
            return try Self.transcode(user)

        default:
            // GET /users
            if endpoint.method == .get, segments.count == 1, segments[0] == "users" {
                let users = await store.allUsers()
                return try Self.transcode(users)
            }
            // GET /users/{id}
            if endpoint.method == .get, segments.count == 2, segments[0] == "users" {
                guard let user = await store.user(id: segments[1]) else { throw APIError.notFound }
                return try Self.transcode(user)
            }
            // PATCH /users/{id}
            if endpoint.method == .patch, segments.count == 2, segments[0] == "users" {
                guard let displayName = endpoint.query["displayName"], !displayName.isEmpty else {
                    throw APIError.custom(message: "A name is required.", retryable: false)
                }
                let user = await store.updateCurrentUserProfile(displayName: displayName, bio: endpoint.query["bio"], avatarURL: endpoint.query["avatarURL"])
                return try Self.transcode(user)
            }
            // GET /conversations/{id}
            if endpoint.method == .get, segments.count == 2, segments[0] == "conversations" {
                guard let conversation = await store.conversation(id: segments[1]) else { throw APIError.notFound }
                return try Self.transcode(conversation)
            }
            // POST /conversations/direct
            if endpoint.method == .post, segments.count == 2, segments[0] == "conversations", segments[1] == "direct" {
                guard let otherUserId = endpoint.query["userId"] else { throw APIError.notFound }
                let currentUserId = await store.currentUser().id
                let conversation = await store.findOrCreateDirectConversation(currentUserId: currentUserId, otherUserId: otherUserId)
                return try Self.transcode(conversation)
            }
            // POST /conversations/{id}/messages
            if endpoint.method == .post, segments.count == 3, segments[0] == "conversations", segments[2] == "messages" {
                guard let text = endpoint.query["text"], !text.isEmpty else {
                    throw APIError.custom(message: "Message can't be empty.", retryable: false)
                }
                let sender = await store.currentUser()
                let message = await store.createMessage(
                    conversationId: segments[1],
                    senderId: sender.id,
                    text: text,
                    replyToMessageId: endpoint.query["replyToMessageId"]
                )
                return try Self.transcode(message)
            }
            // PATCH /conversations/{id}/messages/{messageId}
            if endpoint.method == .patch, segments.count == 4, segments[0] == "conversations", segments[2] == "messages" {
                guard let text = endpoint.query["text"], !text.isEmpty else {
                    throw APIError.custom(message: "Message can't be empty.", retryable: false)
                }
                guard let updated = await store.editMessageText(conversationId: segments[1], messageId: segments[3], newText: text) else {
                    throw APIError.custom(message: "This message can no longer be edited.", retryable: false)
                }
                return try Self.transcode(updated)
            }
            // POST /conversations/{id}/messages/{messageId}/delivery-simulate
            if endpoint.method == .post, segments.count == 5, segments[0] == "conversations", segments[2] == "messages", segments[4] == "delivery-simulate" {
                let conversationId = segments[1]
                let messageId = segments[3]
                try await Task.sleep(nanoseconds: 500_000_000)
                guard var message = await store.transitionDelivery(conversationId: conversationId, messageId: messageId, to: "delivered") else {
                    throw APIError.notFound
                }
                let readReceiptsEnabled = await store.conversation(id: conversationId)?.readReceiptsEnabled ?? true
                if readReceiptsEnabled {
                    try await Task.sleep(nanoseconds: 700_000_000)
                    if let read = await store.transitionDelivery(conversationId: conversationId, messageId: messageId, to: "read") {
                        message = read
                    }
                }
                return try Self.transcode(message)
            }
            // POST /conversations/{id}/messages/{messageId}/consume-view-once
            if endpoint.method == .post, segments.count == 5, segments[0] == "conversations", segments[2] == "messages", segments[4] == "consume-view-once" {
                guard let message = await store.consumeViewOnceAttachment(conversationId: segments[1], messageId: segments[3]) else {
                    throw APIError.notFound
                }
                return try Self.transcode(message)
            }
            // POST /conversations/{id}/messages/{messageId}/reactions
            if endpoint.method == .post, segments.count == 5, segments[0] == "conversations", segments[2] == "messages", segments[4] == "reactions" {
                guard let emoji = endpoint.query["emoji"], !emoji.isEmpty else { throw APIError.notFound }
                let currentUserId = await store.currentUser().id
                guard let updated = await store.toggleReaction(conversationId: segments[1], messageId: segments[3], userId: currentUserId, emoji: emoji) else {
                    throw APIError.notFound
                }
                return try Self.transcode(updated)
            }
            // PUT /conversations/{id}/settings
            if endpoint.method == .put, segments.count == 3, segments[0] == "conversations", segments[2] == "settings" {
                let readReceiptsEnabled = endpoint.query["readReceiptsEnabled"] == "true"
                let disappearingSeconds = endpoint.query["disappearingSeconds"].flatMap(Int.init).flatMap { $0 > 0 ? $0 : nil }
                guard let updated = await store.updateConversationSettings(
                    conversationId: segments[1],
                    readReceiptsEnabled: readReceiptsEnabled,
                    disappearingSeconds: disappearingSeconds
                ) else {
                    throw APIError.notFound
                }
                return try Self.transcode(updated)
            }
            // POST /conversations/{id}/simulate-reply
            if endpoint.method == .post, segments.count == 3, segments[0] == "conversations", segments[2] == "simulate-reply" {
                let conversationId = segments[1]
                guard let conversation = await store.conversation(id: conversationId), conversation.kind == "direct" else {
                    throw APIError.notFound
                }
                let currentUserId = await store.currentUser().id
                guard let otherId = conversation.participantIds.first(where: { $0 != currentUserId }) else {
                    throw APIError.notFound
                }
                try await Task.sleep(nanoseconds: 1_400_000_000)
                let replyText: String
                if let bot = await store.bot(forUserId: otherId) {
                    let lastUserText = await store.lastMessageText(conversationId: conversationId, senderId: currentUserId) ?? ""
                    replyText = BotResponder.reply(capability: bot.capability, toUserText: lastUserText)
                } else {
                    replyText = CannedReplies.random()
                }
                let reply = await store.createMessage(conversationId: conversationId, senderId: otherId, text: replyText, replyToMessageId: nil)
                return try Self.transcode(reply)
            }
            // POST /groups
            if endpoint.method == .post, segments.count == 1, segments[0] == "groups" {
                guard let title = endpoint.query["title"], !title.isEmpty else {
                    throw APIError.custom(message: "A group name is required.", retryable: false)
                }
                let memberIds = endpoint.query["memberIds"]?.split(separator: ",").map(String.init) ?? []
                let owner = await store.currentUser()
                let group = await store.createGroup(title: title, description: endpoint.query["description"], ownerId: owner.id, memberIds: memberIds)
                return try Self.transcode(group)
            }
            // POST /conversations/{id}/members
            if endpoint.method == .post, segments.count == 3, segments[0] == "conversations", segments[2] == "members" {
                guard let newUserId = endpoint.query["userId"] else { throw APIError.notFound }
                let actingUserId = await store.currentUser().id
                guard let updated = await store.addMember(conversationId: segments[1], actingUserId: actingUserId, newUserId: newUserId) else {
                    throw APIError.custom(message: "You don't have permission to add members.", retryable: false)
                }
                return try Self.transcode(updated)
            }
            // PATCH /conversations/{id}/members/{userId}
            if endpoint.method == .patch, segments.count == 4, segments[0] == "conversations", segments[2] == "members" {
                guard let role = endpoint.query["role"] else { throw APIError.notFound }
                let actingUserId = await store.currentUser().id
                guard let updated = await store.updateMemberRole(conversationId: segments[1], actingUserId: actingUserId, targetUserId: segments[3], role: role) else {
                    throw APIError.custom(message: "You don't have permission to change roles.", retryable: false)
                }
                return try Self.transcode(updated)
            }
            // PATCH /conversations/{id}/info
            if endpoint.method == .patch, segments.count == 3, segments[0] == "conversations", segments[2] == "info" {
                guard let title = endpoint.query["title"], !title.isEmpty else {
                    throw APIError.custom(message: "A group name is required.", retryable: false)
                }
                let actingUserId = await store.currentUser().id
                guard let updated = await store.updateGroupInfo(conversationId: segments[1], actingUserId: actingUserId, title: title, description: endpoint.query["description"]) else {
                    throw APIError.custom(message: "You don't have permission to edit this group.", retryable: false)
                }
                return try Self.transcode(updated)
            }
            // PUT /conversations/{id}/mute
            if endpoint.method == .put, segments.count == 3, segments[0] == "conversations", segments[2] == "mute" {
                guard let updated = await store.setMuted(conversationId: segments[1], muted: endpoint.query["muted"] == "true") else {
                    throw APIError.notFound
                }
                return try Self.transcode(updated)
            }
            // PUT /conversations/{id}/pin
            if endpoint.method == .put, segments.count == 3, segments[0] == "conversations", segments[2] == "pin" {
                let actingUserId = await store.currentUser().id
                guard let updated = await store.setPinnedMessage(conversationId: segments[1], actingUserId: actingUserId, messageId: endpoint.query["messageId"]) else {
                    throw APIError.custom(message: "You don't have permission to pin messages.", retryable: false)
                }
                return try Self.transcode(updated)
            }
            // PUT /conversations/{id}/notification-sound
            if endpoint.method == .put, segments.count == 3, segments[0] == "conversations", segments[2] == "notification-sound" {
                guard let sound = endpoint.query["sound"] else { throw APIError.notFound }
                guard let updated = await store.setNotificationSound(conversationId: segments[1], sound: sound) else {
                    throw APIError.notFound
                }
                return try Self.transcode(updated)
            }
            // PUT /conversations/{id}/wallpaper
            if endpoint.method == .put, segments.count == 3, segments[0] == "conversations", segments[2] == "wallpaper" {
                guard let wallpaper = endpoint.query["wallpaper"] else { throw APIError.notFound }
                guard let updated = await store.setWallpaper(conversationId: segments[1], wallpaper: wallpaper) else {
                    throw APIError.notFound
                }
                return try Self.transcode(updated)
            }
            // POST /conversations/{id}/simulate-group-activity
            if endpoint.method == .post, segments.count == 3, segments[0] == "conversations", segments[2] == "simulate-group-activity" {
                let currentUserId = await store.currentUser().id
                let messages = await store.simulateGroupActivity(conversationId: segments[1], currentUserId: currentUserId)
                return try Self.transcode(messages)
            }
            // GET /calls
            if endpoint.method == .get, segments.count == 1, segments[0] == "calls" {
                let calls = await store.allCalls()
                return try Self.transcode(calls)
            }
            // POST /calls
            if endpoint.method == .post, segments.count == 1, segments[0] == "calls" {
                guard let conversationId = endpoint.query["conversationId"],
                      let counterpartId = endpoint.query["counterpartId"],
                      let type = endpoint.query["type"],
                      let direction = endpoint.query["direction"] else {
                    throw APIError.notFound
                }
                let call = await store.createCall(conversationId: conversationId, counterpartId: counterpartId, type: type, direction: direction)
                return try Self.transcode(call)
            }
            // PATCH /calls/{id}
            if endpoint.method == .patch, segments.count == 2, segments[0] == "calls" {
                guard let outcome = endpoint.query["outcome"] else { throw APIError.notFound }
                let duration = Double(endpoint.query["duration"] ?? "0") ?? 0
                guard let updated = await store.updateCallOutcome(callId: segments[1], outcome: outcome, duration: duration) else {
                    throw APIError.notFound
                }
                return try Self.transcode(updated)
            }
            // GET /media-assets
            if endpoint.method == .get, segments.count == 1, segments[0] == "media-assets" {
                let assets = await store.allMediaAssets()
                return try Self.transcode(assets)
            }
            // GET /conversations/{id}/media
            if endpoint.method == .get, segments.count == 3, segments[0] == "conversations", segments[2] == "media" {
                let items = await store.mediaMessages(conversationId: segments[1])
                return try Self.transcode(items)
            }
            // POST /conversations/{id}/media
            if endpoint.method == .post, segments.count == 3, segments[0] == "conversations", segments[2] == "media" {
                guard let assetId = endpoint.query["assetId"], let quality = endpoint.query["quality"] else {
                    throw APIError.notFound
                }
                let sender = await store.currentUser()
                guard let message = await store.createMediaMessage(
                    conversationId: segments[1],
                    senderId: sender.id,
                    assetId: assetId,
                    quality: quality,
                    caption: endpoint.query["caption"] ?? "",
                    isViewOnce: endpoint.query["isViewOnce"] == "true"
                ) else {
                    throw APIError.notFound
                }
                return try Self.transcode(message)
            }
            // GET /stories
            if endpoint.method == .get, segments.count == 1, segments[0] == "stories" {
                let currentUserId = await store.currentUser().id
                let stories = await store.activeStories(viewerId: currentUserId)
                return try Self.transcode(stories)
            }
            // POST /stories
            if endpoint.method == .post, segments.count == 1, segments[0] == "stories" {
                guard let privacy = endpoint.query["privacy"] else { throw APIError.notFound }
                var mediaURL: String?
                if let assetId = endpoint.query["mediaAssetId"] {
                    mediaURL = await store.mediaAsset(id: assetId)?.thumbnailURL
                }
                let sender = await store.currentUser()
                let story = await store.createStory(
                    authorId: sender.id,
                    backgroundColorHex: endpoint.query["backgroundColorHex"],
                    mediaURL: mediaURL,
                    overlayText: endpoint.query["overlayText"],
                    overlayEmoji: endpoint.query["overlayEmoji"],
                    privacy: privacy,
                    notifyOnScreenshot: endpoint.query["notifyOnScreenshot"] == "true",
                    expiryDuration: environment.storyExpiryDuration
                )
                return try Self.transcode(story)
            }
            // GET /stories/highlights/{authorId}
            if endpoint.method == .get, segments.count == 3, segments[0] == "stories", segments[1] == "highlights" {
                let items = await store.highlights(authorId: segments[2])
                return try Self.transcode(items)
            }
            // GET /stories/{id}/viewers
            if endpoint.method == .get, segments.count == 3, segments[0] == "stories", segments[2] == "viewers" {
                guard let story = await store.story(id: segments[1]) else { throw APIError.notFound }
                var viewers: [UserDTO] = []
                for viewerId in story.viewerIds {
                    if let user = await store.user(id: viewerId) { viewers.append(user) }
                }
                return try Self.transcode(viewers)
            }
            // PATCH /stories/{id}
            if endpoint.method == .patch, segments.count == 2, segments[0] == "stories" {
                let isHighlighted = endpoint.query["isHighlighted"] == "true"
                guard let updated = await store.setStoryHighlighted(storyId: segments[1], isHighlighted: isHighlighted) else {
                    throw APIError.notFound
                }
                return try Self.transcode(updated)
            }
            // GET /close-friends
            if endpoint.method == .get, segments.count == 1, segments[0] == "close-friends" {
                let ids = await store.closeFriends()
                return try Self.transcode(ids)
            }
            // GET /device-contacts
            if endpoint.method == .get, segments.count == 1, segments[0] == "device-contacts" {
                let contacts = await store.allDeviceContacts()
                return try Self.transcode(contacts)
            }
            // GET /user-search
            if endpoint.method == .get, segments.count == 1, segments[0] == "user-search" {
                let currentUserId = await store.currentUser().id
                let results = await store.searchUsers(query: endpoint.query["query"] ?? "", excluding: currentUserId)
                return try Self.transcode(results)
            }
            // POST /contact-requests
            if endpoint.method == .post, segments.count == 1, segments[0] == "contact-requests" {
                guard let toUserId = endpoint.query["toUserId"] else { throw APIError.notFound }
                let fromUserId = await store.currentUser().id
                guard let request = await store.sendContactRequest(fromUserId: fromUserId, toUserId: toUserId) else {
                    throw APIError.custom(message: "You're sending requests too quickly. Please wait a bit and try again.", retryable: true)
                }
                return try Self.transcode(request)
            }
            // GET /contact-requests
            if endpoint.method == .get, segments.count == 1, segments[0] == "contact-requests" {
                let currentUserId = await store.currentUser().id
                let requests = await store.incomingRequests(for: currentUserId)
                return try Self.transcode(requests)
            }
            // POST /contact-requests/simulate — demo-only affordance (no second real device
            // to send a real request from), mirrors Module 4's "simulate incoming call".
            if endpoint.method == .post, segments.count == 2, segments[0] == "contact-requests", segments[1] == "simulate" {
                let toUserId = await store.currentUser().id
                guard let request = await store.simulateIncomingRequest(toUserId: toUserId) else { throw APIError.notFound }
                return try Self.transcode(request)
            }
            // PATCH /contact-requests/{id}
            if endpoint.method == .patch, segments.count == 2, segments[0] == "contact-requests" {
                guard let acceptValue = endpoint.query["accept"] else { throw APIError.notFound }
                let actingUserId = await store.currentUser().id
                guard let updated = await store.respondToRequest(requestId: segments[1], actingUserId: actingUserId, accept: acceptValue == "true") else {
                    throw APIError.notFound
                }
                return try Self.transcode(updated)
            }
            // GET /connections
            if endpoint.method == .get, segments.count == 1, segments[0] == "connections" {
                let ids = await store.myConnections()
                var connectedUsers: [UserDTO] = []
                for id in ids {
                    if let user = await store.user(id: id) { connectedUsers.append(user) }
                }
                return try Self.transcode(connectedUsers)
            }
            // GET /discoverability
            if endpoint.method == .get, segments.count == 1, segments[0] == "discoverability" {
                let value = await store.discoverability()
                return try Self.transcode(value)
            }
            // PUT /discoverability
            if endpoint.method == .put, segments.count == 1, segments[0] == "discoverability" {
                guard let value = endpoint.query["value"] else { throw APIError.notFound }
                await store.setDiscoverability(value)
                return try Self.transcode(value)
            }
            // POST /contacts/qr-connect
            if endpoint.method == .post, segments.count == 2, segments[0] == "contacts", segments[1] == "qr-connect" {
                guard let scannedUserId = endpoint.query["userId"] else { throw APIError.notFound }
                let currentUserId = await store.currentUser().id
                guard await store.connectViaQR(currentUserId: currentUserId, scannedUserId: scannedUserId),
                      let user = await store.user(id: scannedUserId) else {
                    throw APIError.notFound
                }
                return try Self.transcode(user)
            }
            // GET /auth/pin/status
            if endpoint.method == .get, segments.count == 2, segments[0] == "auth", segments[1] == "pin-status" {
                let enabled = await store.isAppLockEnabled()
                return try Self.transcode(enabled)
            }
            // POST /auth/pin/verify
            if endpoint.method == .post, segments.count == 2, segments[0] == "auth", segments[1] == "pin-verify" {
                let isValid = await store.verifyAppLockPIN(endpoint.query["pin"] ?? "")
                return try Self.transcode(isValid)
            }
            // GET /privacy/last-seen
            if endpoint.method == .get, segments.count == 2, segments[0] == "privacy", segments[1] == "last-seen" {
                let value = await store.lastSeenVisibility()
                return try Self.transcode(value)
            }
            // PUT /privacy/last-seen
            if endpoint.method == .put, segments.count == 2, segments[0] == "privacy", segments[1] == "last-seen" {
                guard let value = endpoint.query["value"] else { throw APIError.notFound }
                await store.setLastSeenVisibility(value)
                return try Self.transcode(value)
            }
            // GET /privacy/blocked
            if endpoint.method == .get, segments.count == 2, segments[0] == "privacy", segments[1] == "blocked" {
                let ids = await store.blockedUserIds()
                var users: [UserDTO] = []
                for id in ids {
                    if let user = await store.user(id: id) { users.append(user) }
                }
                return try Self.transcode(users)
            }
            // GET /privacy/blocked-status
            if endpoint.method == .get, segments.count == 2, segments[0] == "privacy", segments[1] == "blocked-status" {
                guard let userId = endpoint.query["userId"] else { throw APIError.notFound }
                let isBlocked = await store.isUserBlocked(userId)
                return try Self.transcode(isBlocked)
            }
            // GET /channels
            if endpoint.method == .get, segments.count == 1, segments[0] == "channels" {
                let channels = await store.allChannels()
                return try Self.transcode(channels)
            }
            // GET /channels/mine
            if endpoint.method == .get, segments.count == 2, segments[0] == "channels", segments[1] == "mine" {
                let currentUserId = await store.currentUser().id
                let channels = await store.myChannels(userId: currentUserId)
                return try Self.transcode(channels)
            }
            // GET /channels/{id}
            if endpoint.method == .get, segments.count == 2, segments[0] == "channels" {
                guard let channel = await store.channel(id: segments[1]) else { throw APIError.notFound }
                return try Self.transcode(channel)
            }
            // POST /channels
            if endpoint.method == .post, segments.count == 1, segments[0] == "channels" {
                guard let title = endpoint.query["title"], !title.isEmpty else {
                    throw APIError.custom(message: "A channel name is required.", retryable: false)
                }
                let currentUserId = await store.currentUser().id
                let channel = await store.createChannel(title: title, description: endpoint.query["description"], ownerId: currentUserId)
                return try Self.transcode(channel)
            }
            // POST /channels/{id}/follow
            if endpoint.method == .post, segments.count == 3, segments[0] == "channels", segments[2] == "follow" {
                let currentUserId = await store.currentUser().id
                guard let updated = await store.followChannel(channelId: segments[1], userId: currentUserId) else {
                    throw APIError.notFound
                }
                return try Self.transcode(updated)
            }
            // POST /channels/{id}/unfollow
            if endpoint.method == .post, segments.count == 3, segments[0] == "channels", segments[2] == "unfollow" {
                let currentUserId = await store.currentUser().id
                guard let updated = await store.unfollowChannel(channelId: segments[1], userId: currentUserId) else {
                    throw APIError.notFound
                }
                return try Self.transcode(updated)
            }
            // GET /channels/{id}/posts
            if endpoint.method == .get, segments.count == 3, segments[0] == "channels", segments[2] == "posts" {
                let posts = await store.channelPosts(channelId: segments[1])
                return try Self.transcode(posts)
            }
            // POST /channels/{id}/posts
            if endpoint.method == .post, segments.count == 3, segments[0] == "channels", segments[2] == "posts" {
                guard let text = endpoint.query["text"], !text.isEmpty else {
                    throw APIError.custom(message: "A post needs some text.", retryable: false)
                }
                let currentUserId = await store.currentUser().id
                guard let post = await store.createChannelPost(channelId: segments[1], authorId: currentUserId, text: text) else {
                    throw APIError.custom(message: "Only channel admins can post.", retryable: false)
                }
                return try Self.transcode(post)
            }
            // POST /channels/{id}/posts/{postId}/view
            if endpoint.method == .post, segments.count == 5, segments[0] == "channels", segments[2] == "posts", segments[4] == "view" {
                let currentUserId = await store.currentUser().id
                guard let updated = await store.registerPostView(channelId: segments[1], postId: segments[3], viewerId: currentUserId) else {
                    throw APIError.notFound
                }
                return try Self.transcode(updated)
            }
            // GET /communities
            if endpoint.method == .get, segments.count == 1, segments[0] == "communities" {
                let communities = await store.allCommunities()
                return try Self.transcode(communities)
            }
            // GET /communities/{id}
            if endpoint.method == .get, segments.count == 2, segments[0] == "communities" {
                guard let community = await store.community(id: segments[1]) else { throw APIError.notFound }
                return try Self.transcode(community)
            }
            // POST /communities
            if endpoint.method == .post, segments.count == 1, segments[0] == "communities" {
                guard let title = endpoint.query["title"], !title.isEmpty else {
                    throw APIError.custom(message: "A community name is required.", retryable: false)
                }
                let currentUserId = await store.currentUser().id
                let community = await store.createCommunity(title: title, description: endpoint.query["description"], ownerId: currentUserId)
                return try Self.transcode(community)
            }
            // POST /communities/{id}/link-group
            if endpoint.method == .post, segments.count == 3, segments[0] == "communities", segments[2] == "link-group" {
                guard let conversationId = endpoint.query["conversationId"] else { throw APIError.notFound }
                guard let updated = await store.linkGroup(communityId: segments[1], conversationId: conversationId) else {
                    throw APIError.notFound
                }
                return try Self.transcode(updated)
            }
            // POST /communities/{id}/link-channel
            if endpoint.method == .post, segments.count == 3, segments[0] == "communities", segments[2] == "link-channel" {
                guard let channelId = endpoint.query["channelId"] else { throw APIError.notFound }
                guard let updated = await store.linkChannel(communityId: segments[1], channelId: channelId) else {
                    throw APIError.notFound
                }
                return try Self.transcode(updated)
            }
            // GET /search
            if endpoint.method == .get, segments.count == 1, segments[0] == "search" {
                let text = endpoint.query["q"] ?? ""
                let senderId = endpoint.query["senderId"]
                let hasMediaOnly = endpoint.query["hasMedia"] == "true"
                let conversations = await store.searchConversationsByTitle(text)
                let users = await store.searchUsers(text)
                let messages = await store.searchMessages(
                    conversationId: nil,
                    text: text,
                    senderId: senderId,
                    hasMediaOnly: hasMediaOnly,
                    after: endpoint.query["after"],
                    before: endpoint.query["before"]
                )
                var messageHits: [MessageSearchHitDTO] = []
                for message in messages {
                    let title = await store.conversation(id: message.conversationId)?.title ?? ""
                    messageHits.append(MessageSearchHitDTO(message: message, conversationTitle: title))
                }
                let result = GlobalSearchResultsDTO(conversations: conversations, messages: messageHits, users: users)
                return try Self.transcode(result)
            }
            // GET /conversations/{id}/search
            if endpoint.method == .get, segments.count == 3, segments[0] == "conversations", segments[2] == "search" {
                let messages = await store.searchMessages(
                    conversationId: segments[1],
                    text: endpoint.query["q"] ?? "",
                    senderId: endpoint.query["senderId"],
                    hasMediaOnly: endpoint.query["hasMedia"] == "true",
                    after: endpoint.query["after"],
                    before: endpoint.query["before"]
                )
                return try Self.transcode(messages)
            }
            // GET /wallet
            if endpoint.method == .get, segments.count == 1, segments[0] == "wallet" {
                let currentUserId = await store.currentUser().id
                let wallet = await store.wallet(for: currentUserId)
                return try Self.transcode(wallet)
            }
            // POST /wallet/kyc
            if endpoint.method == .post, segments.count == 2, segments[0] == "wallet", segments[1] == "kyc" {
                guard let fullName = endpoint.query["fullName"], !fullName.isEmpty,
                      let country = endpoint.query["country"], !country.isEmpty else {
                    throw APIError.custom(message: "Full name and country are required.", retryable: false)
                }
                let currentUserId = await store.currentUser().id
                let wallet = await store.submitKYC(userId: currentUserId, fullName: fullName, country: country)
                return try Self.transcode(wallet)
            }
            // POST /wallet/top-up
            if endpoint.method == .post, segments.count == 2, segments[0] == "wallet", segments[1] == "top-up" {
                guard let amount = endpoint.query["amount"].flatMap(Double.init), amount > 0 else {
                    throw APIError.custom(message: "Enter a valid amount.", retryable: false)
                }
                let currentUserId = await store.currentUser().id
                let wallet = await store.topUp(userId: currentUserId, amount: amount)
                return try Self.transcode(wallet)
            }
            // GET /payments
            if endpoint.method == .get, segments.count == 1, segments[0] == "payments" {
                let currentUserId = await store.currentUser().id
                let transactions = await store.paymentTransactions(for: currentUserId)
                return try Self.transcode(transactions)
            }
            // POST /payments/send
            if endpoint.method == .post, segments.count == 2, segments[0] == "payments", segments[1] == "send" {
                guard let toUserId = endpoint.query["toUserId"], let amount = endpoint.query["amount"].flatMap(Double.init) else {
                    throw APIError.notFound
                }
                let currentUserId = await store.currentUser().id
                let senderWallet = await store.wallet(for: currentUserId)
                guard senderWallet.kycStatus == "verified" else {
                    throw APIError.custom(message: "Verify your identity before sending money.", retryable: false)
                }
                guard senderWallet.balance >= amount else {
                    throw APIError.custom(message: "Insufficient balance.", retryable: false)
                }
                guard let transaction = await store.sendMoney(
                    fromUserId: currentUserId,
                    toUserId: toUserId,
                    amount: amount,
                    note: endpoint.query["note"],
                    conversationId: endpoint.query["conversationId"]
                ) else {
                    throw APIError.custom(message: "Couldn't complete this payment.", retryable: true)
                }
                return try Self.transcode(transaction)
            }
            // POST /payments/request
            if endpoint.method == .post, segments.count == 2, segments[0] == "payments", segments[1] == "request" {
                guard let toUserId = endpoint.query["toUserId"], let amount = endpoint.query["amount"].flatMap(Double.init), amount > 0 else {
                    throw APIError.notFound
                }
                let currentUserId = await store.currentUser().id
                let transaction = await store.requestMoney(
                    fromUserId: currentUserId,
                    toUserId: toUserId,
                    amount: amount,
                    note: endpoint.query["note"],
                    conversationId: endpoint.query["conversationId"]
                )
                return try Self.transcode(transaction)
            }
            // POST /payments/{id}/respond
            if endpoint.method == .post, segments.count == 3, segments[0] == "payments", segments[2] == "respond" {
                let accept = endpoint.query["accept"] == "true"
                guard let updated = await store.respondToRequest(transactionId: segments[1], accept: accept) else {
                    throw APIError.custom(message: accept ? "Insufficient balance or identity not verified." : "Couldn't decline this request.", retryable: false)
                }
                return try Self.transcode(updated)
            }
            // GET /bots
            if endpoint.method == .get, segments.count == 1, segments[0] == "bots" {
                let bots = await store.allBots()
                return try Self.transcode(bots)
            }
            throw APIError.notFound
        }
    }

    /// Only message history (`GET /conversations/{id}/messages`) is pageable on the mock backend; every other path throws `APIError.notFound`.
    public func requestPage<T: Decodable & Sendable>(_ endpoint: Endpoint, cursor: String?, pageSize: Int) async throws -> Page<T> {
        try await simulator.simulateLatency()
        try simulator.maybeThrowInjectedError(for: endpoint)

        guard endpoint.method == .get,
              endpoint.path.hasPrefix("/conversations/"),
              endpoint.path.hasSuffix("/messages") else {
            throw APIError.notFound
        }

        let conversationId = String(
            endpoint.path
                .dropFirst("/conversations/".count)
                .dropLast("/messages".count)
        )
        let result = await store.messagesPage(conversationId: conversationId, cursor: cursor, pageSize: pageSize)
        let items: [T] = try Self.transcode(result.items)
        return Page(items: items, nextCursor: result.nextCursor, hasMore: result.hasMore)
    }

    /// For routes whose response body is ignored. Same routing rules as `request`.
    public func requestVoid(_ endpoint: Endpoint) async throws {
        try await simulator.simulateLatency()
        try simulator.maybeThrowInjectedError(for: endpoint)

        let segments = Self.pathSegments(endpoint.path)

        switch (endpoint.method, endpoint.path) {
        case (.put, "/auth/pin"):
            await store.setAppLockPIN(endpoint.query["pin"])
        default:
            // DELETE /conversations/{id}/messages/{messageId}
            if endpoint.method == .delete, segments.count == 4, segments[0] == "conversations", segments[2] == "messages" {
                guard await store.deleteMessage(conversationId: segments[1], messageId: segments[3]) else {
                    throw APIError.custom(message: "This message can no longer be deleted.", retryable: false)
                }
                return
            }
            // DELETE /conversations/{id}/members/{userId}
            if endpoint.method == .delete, segments.count == 4, segments[0] == "conversations", segments[2] == "members" {
                let actingUserId = await store.currentUser().id
                guard await store.removeMember(conversationId: segments[1], actingUserId: actingUserId, targetUserId: segments[3]) != nil else {
                    throw APIError.custom(message: "You don't have permission to remove this member.", retryable: false)
                }
                return
            }
            // POST /stories/{id}/view
            if endpoint.method == .post, segments.count == 3, segments[0] == "stories", segments[2] == "view" {
                let viewerId = await store.currentUser().id
                await store.markStoryViewed(storyId: segments[1], viewerId: viewerId)
                return
            }
            // DELETE /stories/{id}
            if endpoint.method == .delete, segments.count == 2, segments[0] == "stories" {
                await store.deleteStory(storyId: segments[1])
                return
            }
            // PUT /close-friends
            if endpoint.method == .put, segments.count == 1, segments[0] == "close-friends" {
                let ids = endpoint.query["userIds"]?.split(separator: ",").map(String.init) ?? []
                await store.setCloseFriends(ids)
                return
            }
            // POST /privacy/block
            if endpoint.method == .post, segments.count == 2, segments[0] == "privacy", segments[1] == "block" {
                guard let userId = endpoint.query["userId"] else { throw APIError.notFound }
                await store.blockUser(userId)
                return
            }
            // POST /privacy/unblock
            if endpoint.method == .post, segments.count == 2, segments[0] == "privacy", segments[1] == "unblock" {
                guard let userId = endpoint.query["userId"] else { throw APIError.notFound }
                await store.unblockUser(userId)
                return
            }
            // POST /privacy/report
            if endpoint.method == .post, segments.count == 2, segments[0] == "privacy", segments[1] == "report" {
                guard let userId = endpoint.query["userId"], let reason = endpoint.query["reason"] else { throw APIError.notFound }
                await store.addReport(reportedUserId: userId, reason: reason)
                return
            }
            throw APIError.notFound
        }
    }

    private static func pathSegments(_ path: String) -> [String] {
        path.split(separator: "/").map(String.init)
    }

    /// Re-encodes the DTO to JSON and decodes it as the caller's type, so mock results go through the same `Codable` path as real responses. Failures surface as `APIError.decoding`.
    private static func transcode<T: Decodable>(_ value: some Encodable) throws -> T {
        let data: Data
        do {
            data = try JSONEncoder().encode(value)
        } catch {
            throw APIError.decoding(underlying: "\(error)")
        }
        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw APIError.decoding(underlying: "\(error)")
        }
    }
}
