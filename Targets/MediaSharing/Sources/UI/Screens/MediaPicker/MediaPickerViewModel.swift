import Foundation
import Observation
import Core
import Mock

/// Loads the assets offered by the repository (there is no system photo-library or permission flow here) and tracks the selection that drives navigation to compose.
@MainActor
@Observable
final class MediaPickerViewModel {
    let conversationId: String
    private(set) var assetsState: LoadableState<[MediaAsset]> = .idle
    /// Not `private(set)`: the screen binds it to `navigationDestination(item:)`, so popping compose resets it to nil.
    var selectedAsset: MediaAsset?

    @ObservationIgnored private var isPreview = false
    private let repository: IMediaRepository

    init(conversationId: String, repository: IMediaRepository = MediaRepository()) {
        self.conversationId = conversationId
        self.repository = repository
    }

    var assets: [MediaAsset] {
        assetsState.value ?? []
    }

    func load() async {
        guard !isPreview else { return }
        assetsState = .loading
        do {
            let items = try await repository.availableAssets()
            assetsState = items.isEmpty ? .empty : .loaded(items)
        } catch {
            assetsState = .failed(error.asAppError)
        }
    }

    func select(_ asset: MediaAsset) {
        selectedAsset = asset
    }
}

#if DEBUG
extension MediaPickerViewModel {
    convenience init(previewScenario scenario: PreviewScenario) {
        self.init(conversationId: PreviewData.directConversation.id)
        isPreview = true
        assetsState = scenario.state(PreviewData.mediaAssets)
    }
}
#endif
