@testable import Talkora
import Foundation
import XCTest
@testable import Core
@testable import MediaSharing

private func makeMessage(_ id: String, text: String = "", attachment: MediaAttachment? = nil) -> Message {
    Message(id: id, conversationId: "conv1", senderId: "me", text: text, createdAt: Date(), attachment: attachment)
}

private func makeAsset(_ id: String, kind: MediaKind = .image, size: Int = 1000) -> MediaAsset {
    MediaAsset(id: id, kind: kind, fileName: "\(id).dat", thumbnailURL: nil, originalSizeBytes: size, durationSeconds: nil)
}

@MainActor
final class MediaComposeViewModelTests: XCTestCase {
    private func makeViewModel(asset: MediaAsset = makeAsset("a1"), repository: StubMediaRepository = StubMediaRepository()) -> MediaComposeViewModel {
        MediaComposeViewModel(asset: asset, conversationId: "conv1", repository: repository)
    }

    func test_estimatedSize_image_compressedIsSmallerThanOriginal() {
        let viewModel = makeViewModel(asset: makeAsset("a1", kind: .image, size: 1000))

        XCTAssertEqual(viewModel.estimatedSize(for: .original), 1000)
        XCTAssertEqual(viewModel.estimatedSize(for: .compressed), 220)
    }

    func test_estimatedSize_file_isAlwaysOriginalSize() {
        let viewModel = makeViewModel(asset: makeAsset("f1", kind: .file, size: 1000))

        XCTAssertEqual(viewModel.estimatedSize(for: .compressed), 1000)
    }

    func test_send_success_returnsMessage() async {
        let stub = StubMediaRepository()
        stub.sendMediaResult = .success(makeMessage("m1"))
        let viewModel = makeViewModel(repository: stub)
        viewModel.caption = "hi"

        let message = await viewModel.send()

        XCTAssertEqual(message?.id, "m1")
        XCTAssertFalse(viewModel.isSending)
        XCTAssertNil(viewModel.sendError)
    }

    func test_send_failure_setsSendErrorAndReturnsNil() async {
        let viewModel = makeViewModel()

        let message = await viewModel.send()

        XCTAssertNil(message)
        XCTAssertNotNil(viewModel.sendError)
        XCTAssertFalse(viewModel.isSending)
    }
}
