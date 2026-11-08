#if DEBUG
@testable import Talkora
import XCTest
@testable import Core
@testable import Mock
@testable import Messaging
@testable import MediaSharing
@testable import Reactions

/// Guards the Search / MediaSharing / Reactions / chat-settings previews: each preview ViewModel
/// must build without repositories and keep its canned state.
@MainActor
final class PreviewSmokeSearchMediaTests: XCTestCase {
    func test_globalSearch_loadedHasResults() async {
        let viewModel = GlobalSearchViewModel(previewScenario: .loaded)
        XCTAssertFalse(viewModel.results.isEmpty)
        XCTAssertFalse(viewModel.isSearching)
        try? await Task.sleep(nanoseconds: 400_000_000)
        XCTAssertFalse(viewModel.results.isEmpty)
        XCTAssertFalse(viewModel.isSearching)
    }

    func test_globalSearch_loadingAndEmpty() async {
        let loading = GlobalSearchViewModel(previewScenario: .loading)
        XCTAssertTrue(loading.isSearching)
        let empty = GlobalSearchViewModel(previewScenario: .empty)
        XCTAssertTrue(empty.results.isEmpty)
        XCTAssertFalse(empty.isSearching)
        try? await Task.sleep(nanoseconds: 400_000_000)
        XCTAssertTrue(loading.isSearching)
        XCTAssertTrue(empty.results.isEmpty)
    }

    func test_inChatSearch_scenarios() async {
        let loaded = InChatSearchViewModel(previewScenario: .loaded)
        let loading = InChatSearchViewModel(previewScenario: .loading)
        let empty = InChatSearchViewModel(previewScenario: .empty)
        XCTAssertFalse(loaded.results.isEmpty)
        XCTAssertTrue(loading.isSearching)
        XCTAssertTrue(empty.results.isEmpty)
        XCTAssertFalse(empty.isSearching)
        try? await Task.sleep(nanoseconds: 400_000_000)
        XCTAssertFalse(loaded.results.isEmpty)
        XCTAssertFalse(loaded.isSearching)
        XCTAssertTrue(loading.isSearching)
        XCTAssertTrue(empty.results.isEmpty)
    }

    func test_mediaHistory_scenarios() async {
        let loaded = MediaHistoryViewModel(previewScenario: .loaded)
        XCTAssertFalse(loaded.filteredItems.isEmpty)
        XCTAssertTrue(MediaHistoryViewModel(previewScenario: .loading).state.isLoading)
        guard case .empty = MediaHistoryViewModel(previewScenario: .empty).state else { return XCTFail("expected empty") }
        guard case .failed = MediaHistoryViewModel(previewScenario: .failed).state else { return XCTFail("expected failed") }
        await loaded.load()
        XCTAssertFalse(loaded.filteredItems.isEmpty)
    }

    func test_mediaPicker_scenarios() async {
        let loaded = MediaPickerViewModel(previewScenario: .loaded)
        XCTAssertFalse(loaded.assets.isEmpty)
        XCTAssertTrue(MediaPickerViewModel(previewScenario: .loading).assetsState.isLoading)
        guard case .empty = MediaPickerViewModel(previewScenario: .empty).assetsState else { return XCTFail("expected empty") }
        guard case .failed = MediaPickerViewModel(previewScenario: .failed).assetsState else { return XCTFail("expected failed") }
        await loaded.load()
        XCTAssertFalse(loaded.assets.isEmpty)
    }

    func test_mediaCompose_scenarios() throws {
        let asset = try XCTUnwrap(PreviewData.mediaAssets.first)
        XCTAssertTrue(MediaComposeViewModel(previewScenario: .empty, asset: asset).caption.isEmpty)
        XCTAssertFalse(MediaComposeViewModel(previewScenario: .filled, asset: asset).caption.isEmpty)
        XCTAssertTrue(MediaComposeViewModel(previewScenario: .submitting, asset: asset).isSending)
        XCTAssertNotNil(MediaComposeViewModel(previewScenario: .failed, asset: asset).sendError)
    }

    func test_reactionAnalytics_scenarios() async {
        let loaded = ReactionAnalyticsViewModel(previewScenario: .loaded)
        XCTAssertFalse(loaded.state.value?.emojiTotals.isEmpty ?? true)
        XCTAssertTrue(ReactionAnalyticsViewModel(previewScenario: .loading).state.isLoading)
        guard case .empty = ReactionAnalyticsViewModel(previewScenario: .empty).state else { return XCTFail("expected empty") }
        guard case .failed = ReactionAnalyticsViewModel(previewScenario: .failed).state else { return XCTFail("expected failed") }
        await loaded.load()
        XCTAssertNotNil(loaded.state.value)
    }

    func test_chatSettings_directAndGroup() {
        let direct = ChatSettingsViewModel(
            conversation: PreviewData.directConversation,
            otherParticipant: PreviewData.users.first,
            isBlockedParticipant: false,
            onConversationChanged: { _ in },
            onBlockChanged: { _ in }
        )
        XCTAssertFalse(direct.isGroup)
        let group = ChatSettingsViewModel(
            conversation: PreviewData.groupConversation,
            otherParticipant: nil,
            isBlockedParticipant: false,
            onConversationChanged: { _ in },
            onBlockChanged: { _ in }
        )
        XCTAssertTrue(group.isGroup)
    }

    func test_chatWallpaperPicker_keepsSelection() {
        let viewModel = ChatWallpaperPickerViewModel(conversationId: PreviewData.directConversation.id, selected: .ocean, onChanged: { _ in })
        XCTAssertEqual(viewModel.selected, .ocean)
    }
}
#endif
