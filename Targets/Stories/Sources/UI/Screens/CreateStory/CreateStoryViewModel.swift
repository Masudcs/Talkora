import Foundation
import Observation
import Core
import Mock

/// Composer state for a new story: a solid colour or an image from the media library, optional text and emoji overlay, privacy, and screenshot notification.
@MainActor
@Observable
final class CreateStoryViewModel {
    /// Makes `loadMediaAssets()` and `post()` no-ops in previews. Not observed because the UI never reads it.
    @ObservationIgnored private var isPreview = false
    static let backgroundColors = ["#007AFF", "#FF9500", "#34C759", "#FF2D55", "#5856D6", "#8E8E93"]
    static let emojiOptions = ["😀", "😂", "❤️", "🔥", "🎉", "😢", "👍", "🙌", "😍", "🥳", "✨", "💯"]

    /// Library images that can be used as a background; videos are filtered out.
    private(set) var mediaAssetsState: LoadableState<[MediaAsset]> = .idle
    var selectedBackgroundColorHex: String = CreateStoryViewModel.backgroundColors[0]
    /// When set it overrides the background colour on post.
    var selectedMediaAsset: MediaAsset?
    var overlayText: String = ""
    var overlayEmoji: String?
    /// Audience: everyone, close friends only, or only the author.
    var privacy: StoryPrivacy = .everyone
    /// Stored on the story as a preference; the mock backend cannot actually detect screenshots.
    var notifyOnScreenshot: Bool = false
    var isManagingCloseFriends = false
    private(set) var isPosting = false
    private(set) var postError: AppError?

    private let mediaRepository: IMediaRepository
    private let storyRepository: IStoryRepository

    init(mediaRepository: IMediaRepository = MediaRepository(), storyRepository: IStoryRepository = StoryRepository()) {
        self.mediaRepository = mediaRepository
        self.storyRepository = storyRepository
    }

    func loadMediaAssets() async {
        guard !isPreview else { return }
        mediaAssetsState = .loading
        do {
            let items = try await mediaRepository.availableAssets().filter { $0.kind == .image }
            mediaAssetsState = items.isEmpty ? .empty : .loaded(items)
        } catch {
            mediaAssetsState = .failed(error.asAppError)
        }
    }

    /// Picking a colour clears any selected image so the two are mutually exclusive.
    func selectBackgroundColor(_ hex: String) {
        selectedBackgroundColorHex = hex
        selectedMediaAsset = nil
    }

    func selectMediaAsset(_ asset: MediaAsset) {
        selectedMediaAsset = asset
    }

    func toggleEmoji(_ emoji: String) {
        overlayEmoji = overlayEmoji == emoji ? nil : emoji
    }

    /// Creates the story and returns it, or `nil` on failure (with `postError` set; preview mode also returns `nil`). Sends either the colour or the media id, never both; an empty overlay text is sent as `nil`. `postError` is not cleared on a retry.
    func post() async -> Story? {
        guard !isPreview else { return nil }
        isPosting = true
        defer { isPosting = false }
        do {
            return try await storyRepository.createStory(
                backgroundColorHex: selectedMediaAsset == nil ? selectedBackgroundColorHex : nil,
                mediaAssetId: selectedMediaAsset?.id,
                overlayText: overlayText.isEmpty ? nil : overlayText,
                overlayEmoji: overlayEmoji,
                privacy: privacy,
                notifyOnScreenshot: notifyOnScreenshot
            )
        } catch {
            postError = error.asAppError
            return nil
        }
    }
}

#if DEBUG
extension CreateStoryViewModel {
    convenience init(previewScenario scenario: FormPreviewScenario) {
        self.init()
        isPreview = true
        mediaAssetsState = .loaded(PreviewData.mediaAssets.filter { $0.kind == .image })
        switch scenario {
        case .empty, .invalid:
            break
        case .filled:
            overlayText = "Sunday vibes"
            overlayEmoji = "🔥"
            selectedBackgroundColorHex = Self.backgroundColors[3]
            privacy = .closeFriends
        case .submitting:
            overlayText = "Sunday vibes"
            overlayEmoji = "🔥"
            isPosting = true
        case .failed:
            overlayText = "Sunday vibes"
            postError = PreviewData.error
        }
    }
}
#endif
