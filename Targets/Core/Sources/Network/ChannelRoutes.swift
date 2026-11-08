import Foundation

/// Broadcast channels, their posts, and communities (which group conversations and channels). `myChannels` is the current user's own list.
public enum ChannelRoutes: EndpointConvertible {
    case allChannels
    case myChannels
    case channel(id: String)
    case createChannel(title: String, description: String?)
    case follow(channelId: String)
    case unfollow(channelId: String)
    case posts(channelId: String)
    case createPost(channelId: String, text: String)
    case registerView(channelId: String, postId: String)
    case communities
    case community(id: String)
    case createCommunity(title: String, description: String?)
    case linkGroup(communityId: String, conversationId: String)
    case linkChannel(communityId: String, channelId: String)

    public var endpoint: Endpoint {
        switch self {
        case .allChannels:
            return Endpoint(path: "/channels")
        case .myChannels:
            return Endpoint(path: "/channels/mine")
        case .channel(let id):
            return Endpoint(path: "/channels/\(id)")
        case .createChannel(let title, let description):
            return Endpoint(path: "/channels", method: .post, body: TitleBody(title: title, description: description))
        case .follow(let channelId):
            return Endpoint(path: "/channels/\(channelId)/follow", method: .post)
        case .unfollow(let channelId):
            return Endpoint(path: "/channels/\(channelId)/unfollow", method: .post)
        case .posts(let channelId):
            return Endpoint(path: "/channels/\(channelId)/posts")
        case .createPost(let channelId, let text):
            return Endpoint(path: "/channels/\(channelId)/posts", method: .post, body: TextBody(text: text))
        case .registerView(let channelId, let postId):
            return Endpoint(path: "/channels/\(channelId)/posts/\(postId)/view", method: .post)
        case .communities:
            return Endpoint(path: "/communities")
        case .community(let id):
            return Endpoint(path: "/communities/\(id)")
        case .createCommunity(let title, let description):
            return Endpoint(path: "/communities", method: .post, body: TitleBody(title: title, description: description))
        case .linkGroup(let communityId, let conversationId):
            return Endpoint(path: "/communities/\(communityId)/link-group", method: .post, body: ConversationIdBody(conversationId: conversationId))
        case .linkChannel(let communityId, let channelId):
            return Endpoint(path: "/communities/\(communityId)/link-channel", method: .post, body: ChannelIdBody(channelId: channelId))
        }
    }
}

// MARK: - Request bodies

/// Encodable request bodies for these routes.
public extension ChannelRoutes {
    struct TitleBody: Encodable, Sendable { let title: String; let description: String? }
    struct TextBody: Encodable, Sendable { let text: String }
    struct ConversationIdBody: Encodable, Sendable { let conversationId: String }
    struct ChannelIdBody: Encodable, Sendable { let channelId: String }
}
