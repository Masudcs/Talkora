@testable import Talkora
import Foundation
import XCTest
@testable import Core
@testable import Stories

private func makeStory(_ id: String, author: String) -> Story {
    Story(id: id, authorId: author, createdAt: Date(), expiresAt: Date().addingTimeInterval(3600),
          backgroundColorHex: nil, mediaURL: nil, overlayText: "hi", overlayEmoji: nil,
          privacy: .everyone, notifyOnScreenshot: false, viewerIds: [], isHighlighted: false)
}

private func makeAsset(_ id: String, kind: MediaKind = .image) -> MediaAsset {
    MediaAsset(id: id, kind: kind, fileName: "\(id).jpg", thumbnailURL: nil, originalSizeBytes: 100, durationSeconds: nil)
}

@MainActor
final class CreateStoryViewModelTests: XCTestCase {
    private func makeViewModel(media: StubMediaRepository = StubMediaRepository(),
                               stories: StubStoryRepository = StubStoryRepository()) -> CreateStoryViewModel {
        CreateStoryViewModel(mediaRepository: media, storyRepository: stories)
    }

    func test_loadMediaAssets_success_keepsOnlyImages() async {
        let media = StubMediaRepository()
        media.availableAssetsResult = .success([makeAsset("a"), makeAsset("v", kind: .video), makeAsset("b")])
        let viewModel = makeViewModel(media: media)

        await viewModel.loadMediaAssets()

        XCTAssertEqual(viewModel.mediaAssetsState.value?.map(\.id), ["a", "b"])
    }

    func test_loadMediaAssets_onlyNonImages_setsEmpty() async {
        let media = StubMediaRepository()
        media.availableAssetsResult = .success([makeAsset("v", kind: .video)])
        let viewModel = makeViewModel(media: media)

        await viewModel.loadMediaAssets()

        guard case .empty = viewModel.mediaAssetsState else {
            return XCTFail("Expected .empty, got \(viewModel.mediaAssetsState)")
        }
    }

    func test_loadMediaAssets_failure_setsFailed() async {
        let media = StubMediaRepository()
        media.availableAssetsResult = .failure(StubFailure.notConfigured)
        let viewModel = makeViewModel(media: media)

        await viewModel.loadMediaAssets()

        XCTAssertNotNil(viewModel.mediaAssetsState.error)
    }

    func test_selectBackgroundColor_clearsSelectedMedia() {
        let viewModel = makeViewModel()
        viewModel.selectMediaAsset(makeAsset("a"))

        viewModel.selectBackgroundColor("#FF9500")

        XCTAssertNil(viewModel.selectedMediaAsset)
        XCTAssertEqual(viewModel.selectedBackgroundColorHex, "#FF9500")
    }

    func test_toggleEmoji_setsThenClears() {
        let viewModel = makeViewModel()

        viewModel.toggleEmoji("🔥")
        XCTAssertEqual(viewModel.overlayEmoji, "🔥")

        viewModel.toggleEmoji("🔥")
        XCTAssertNil(viewModel.overlayEmoji)
    }

    func test_post_success_returnsStoryAndResetsIsPosting() async {
        let stories = StubStoryRepository()
        stories.createStoryResult = .success(makeStory("s1", author: "me"))
        let viewModel = makeViewModel(stories: stories)

        let story = await viewModel.post()

        XCTAssertEqual(story?.id, "s1")
        XCTAssertFalse(viewModel.isPosting)
        XCTAssertNil(viewModel.postError)
    }

    func test_post_failure_returnsNilAndSetsError() async {
        let viewModel = makeViewModel()

        let story = await viewModel.post()

        XCTAssertNil(story)
        XCTAssertNotNil(viewModel.postError)
        XCTAssertFalse(viewModel.isPosting)
    }
}
