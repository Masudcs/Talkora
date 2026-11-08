import Foundation

/// Media library and sending media into a conversation. An empty caption is sent as no caption at all.
public enum MediaRoutes: EndpointConvertible {
    case assets
    case sendMedia(conversationId: String, assetId: String, quality: String, caption: String?, isViewOnce: Bool)
    case history(conversationId: String)

    public var endpoint: Endpoint {
        switch self {
        case .assets:
            return Endpoint(path: "/media-assets")
        case .sendMedia(let conversationId, let assetId, let quality, let caption, let isViewOnce):
            return Endpoint(path: "/conversations/\(conversationId)/media", method: .post,
                            body: SendMediaBody(assetId: assetId, quality: quality, caption: caption?.isEmpty == false ? caption : nil, isViewOnce: isViewOnce))
        case .history(let conversationId):
            return Endpoint(path: "/conversations/\(conversationId)/media")
        }
    }
}

// MARK: - Request bodies

public extension MediaRoutes {
    struct SendMediaBody: Encodable, Sendable { let assetId: String; let quality: String; let caption: String?; let isViewOnce: Bool }
}
