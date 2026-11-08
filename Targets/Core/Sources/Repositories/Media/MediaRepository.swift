import Foundation

/// The media catalog, sending media and media history, over `APIClientProtocol` — behaves the same against the mock, stubbed and live backends.
public final class MediaRepository: IMediaRepository {
    private let api: APIClientProtocol

    public init(api: APIClientProtocol = APIClientProvider.shared.client) {
        self.api = api
    }

    public func availableAssets() async throws -> [MediaAsset] {
        let dtos: [MediaAssetDTO] = try await api.request(MediaRoutes.assets)
        return dtos.map { $0.toDomain() }
    }

    public func sendMedia(conversationId: String, assetId: String, quality: MediaQuality, caption: String?, isViewOnce: Bool) async throws -> Message {
        let dto: MessageDTO = try await api.request(
            MediaRoutes.sendMedia(conversationId: conversationId, assetId: assetId, quality: quality.rawValue, caption: caption, isViewOnce: isViewOnce)
        )
        return dto.toDomain()
    }

    public func mediaHistory(conversationId: String) async throws -> [Message] {
        let dtos: [MessageDTO] = try await api.request(MediaRoutes.history(conversationId: conversationId))
        return dtos.map { $0.toDomain() }
    }
}
