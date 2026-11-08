import Foundation

public protocol IMediaRepository: Sendable {
    /// The mock "camera roll / files" catalog a user can pick from to send.
    func availableAssets() async throws -> [MediaAsset]
    func sendMedia(conversationId: String, assetId: String, quality: MediaQuality, caption: String?, isViewOnce: Bool) async throws -> Message
    /// Backs the per-conversation "Media & Files" tab — Improve: a real unified view
    /// instead of scattered attachments buried in scroll history.
    func mediaHistory(conversationId: String) async throws -> [Message]
}
