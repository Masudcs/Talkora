#if DEBUG
import Foundation
import Core

/// Realistic sample models for `#Preview`s, built from the same fixtures the mock backend seeds
/// so previews match what the running app shows.
public enum PreviewData {
    private struct SampleError: Error {}

    /// Isolated defaults so previews never read or write the real session or theme.
    public static let defaults = UserDefaults(suiteName: "com.talkora.preview") ?? .standard

    public static let error: AppError = GenericAppError(underlying: SampleError(), userMessage: "Something went wrong. Please try again.")

    public static let currentUser: User = UserFixtures.currentUser.toDomain()
    public static let users: [User] = UserFixtures.seed.map { $0.toDomain() }
    public static let conversations: [Conversation] = ConversationFixtures.seed.map { $0.toDomain() }
    public static let calls: [Call] = CallFixtures.seed.map { $0.toDomain() }
    public static let stories: [Story] = StoryFixtures.seed(expiryDuration: 24 * 60 * 60).map { $0.toDomain() }
    public static let channels: [Channel] = ChannelFixtures.seed.map { $0.toDomain(currentUserId: currentUser.id) }
    public static let communities: [Community] = CommunityFixtures.seed.map { $0.toDomain() }
    public static let transactions: [PaymentTransaction] = PaymentTransactionFixtures.seed.map { $0.toDomain() }
    public static let wallet: Wallet = WalletFixtures.seed[currentUser.id]?.toDomain() ?? Wallet(balance: 125, kycStatus: .verified)

    public static var directConversation: Conversation {
        conversations.first { $0.kind == .direct } ?? conversations[0]
    }

    public static var groupConversation: Conversation {
        conversations.first { $0.kind == .group } ?? conversations[0]
    }

    public static func messages(in conversationId: String) -> [Message] {
        (MessageFixtures.seed[conversationId] ?? []).map { $0.toDomain() }
    }

    public static func user(_ id: String?) -> User? {
        users.first { $0.id == id }
    }

    public static func channelPosts(in channelId: String) -> [ChannelPost] {
        (ChannelPostFixtures.seed[channelId] ?? []).map { $0.toDomain() }
    }

    /// A channel the current user administers, to preview the compose bar.
    public static var adminChannel: Channel {
        channels.first { $0.isAdmin(currentUser.id) } ?? channels[0]
    }

    /// A channel the current user only follows or can follow.
    public static var followerChannel: Channel {
        channels.first { !$0.isAdmin(currentUser.id) } ?? channels[0]
    }

    public static let mediaAssets: [MediaAsset] = MediaAssetFixtures.seed.map { $0.toDomain() }

    /// Contacts shown as blocked in the Privacy preview.
    public static var blockedUsers: [User] {
        Array(users.filter { $0.id != currentUser.id }.prefix(2))
    }

    /// User id -> display name, for ViewModels that resolve names separately.
    public static var userNames: [String: String] {
        Dictionary(uniqueKeysWithValues: users.map { ($0.id, $0.displayName) })
    }
}
#endif
