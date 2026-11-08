@testable import Talkora
import Foundation
import XCTest
@testable import Core
@testable import MediaSharing

private func makeAsset(_ id: String, kind: MediaKind = .image, size: Int = 1000) -> MediaAsset {
    MediaAsset(id: id, kind: kind, fileName: "\(id).dat", thumbnailURL: nil, originalSizeBytes: size, durationSeconds: nil)
}

@MainActor
final class MediaPickerViewModelTests: XCTestCase {
    func test_load_success_setsLoadedStateAndAssets() async {
        let stub = StubMediaRepository()
        stub.availableAssetsResult = .success([makeAsset("a1"), makeAsset("a2")])
        let viewModel = MediaPickerViewModel(conversationId: "conv1", repository: stub)

        await viewModel.load()

        XCTAssertEqual(viewModel.assets.map(\.id), ["a1", "a2"])
    }

    func test_load_empty_setsEmptyState() async {
        let viewModel = MediaPickerViewModel(conversationId: "conv1", repository: StubMediaRepository())

        await viewModel.load()

        guard case .empty = viewModel.assetsState else { return XCTFail("expected empty, got \(viewModel.assetsState)") }
        XCTAssertTrue(viewModel.assets.isEmpty)
    }

    func test_load_failure_setsFailedState() async {
        let stub = StubMediaRepository()
        stub.availableAssetsResult = .failure(StubFailure.notConfigured)
        let viewModel = MediaPickerViewModel(conversationId: "conv1", repository: stub)

        await viewModel.load()

        XCTAssertNotNil(viewModel.assetsState.error)
    }

    func test_select_setsSelectedAsset() {
        let viewModel = MediaPickerViewModel(conversationId: "conv1", repository: StubMediaRepository())

        viewModel.select(makeAsset("a1"))

        XCTAssertEqual(viewModel.selectedAsset?.id, "a1")
    }
}
