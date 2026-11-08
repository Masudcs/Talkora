import Foundation
import Observation
import Core
import Mock

/// Form state for sending one asset to a conversation.
@MainActor
@Observable
final class MediaComposeViewModel {
    let asset: MediaAsset
    let conversationId: String
    var caption: String = ""
    var quality: MediaQuality = .compressed
    /// Ignored for `.file` assets (forced off in `send()`), even if the flag was toggled.
    var isViewOnce: Bool = false
    private(set) var isSending = false
    private(set) var sendError: AppError?

    private let repository: IMediaRepository

    init(asset: MediaAsset, conversationId: String, repository: IMediaRepository = MediaRepository()) {
        self.asset = asset
        self.conversationId = conversationId
        self.repository = repository
    }

    /// Improve: the size difference between original and compressed is shown up front,
    /// not hidden behind automatic, invisible compression.
    func estimatedSize(for quality: MediaQuality) -> Int {
        guard asset.kind != .file else { return asset.originalSizeBytes }
        return quality == .compressed ? Int(Double(asset.originalSizeBytes) * 0.22) : asset.originalSizeBytes
    }

    /// Returns the sent message, or nil after setting `sendError`; an empty caption is sent as nil.
    func send() async -> Message? {
        isSending = true
        defer { isSending = false }
        do {
            return try await repository.sendMedia(
                conversationId: conversationId,
                assetId: asset.id,
                quality: quality,
                caption: caption.isEmpty ? nil : caption,
                isViewOnce: asset.kind != .file && isViewOnce
            )
        } catch {
            sendError = error.asAppError
            return nil
        }
    }
}

#if DEBUG
extension MediaComposeViewModel {
    convenience init(previewScenario scenario: FormPreviewScenario, asset: MediaAsset) {
        self.init(asset: asset, conversationId: PreviewData.directConversation.id)
        switch scenario {
        case .empty, .invalid:
            break
        case .filled:
            caption = "Look at this!"
        case .submitting:
            caption = "Look at this!"
            isSending = true
        case .failed:
            caption = "Look at this!"
            sendError = PreviewData.error
        }
    }
}
#endif
