@testable import Talkora
import Foundation
@testable import Core

final class StubMediaRepository: IMediaRepository {
    var availableAssetsResult: Result<[MediaAsset], Error> = .success([])
    var sendMediaResult: Result<Message, Error> = .failure(StubFailure.notConfigured)
    var mediaHistoryResult: Result<[Message], Error> = .success([])

    func availableAssets() async throws -> [MediaAsset] {
        try availableAssetsResult.get()
    }

    func sendMedia(conversationId: String, assetId: String, quality: MediaQuality, caption: String?, isViewOnce: Bool) async throws -> Message {
        try sendMediaResult.get()
    }

    func mediaHistory(conversationId: String) async throws -> [Message] {
        try mediaHistoryResult.get()
    }
}
