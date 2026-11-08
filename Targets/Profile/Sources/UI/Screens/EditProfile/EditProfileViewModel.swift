import Foundation
import Observation
import Core
import Mock

/// Backs `EditProfileScreen`: edits are held locally and only sent to the repository on `save()`.
@MainActor
@Observable
final class EditProfileViewModel {
    /// Preview-only flag that makes `loadAvatarChoices()` a no-op so seeded state isn't overwritten. `@ObservationIgnored` because the UI never reads it.
    @ObservationIgnored private var isPreview = false
    var displayName: String
    var bio: String
    /// Starts as the user's current avatar; changed only by `selectAvatar(_:)`.
    private(set) var selectedAvatarURL: URL?
    private(set) var avatarChoicesState: LoadableState<[MediaAsset]> = .idle
    private(set) var state: LoadableState<User> = .idle

    private let userRepository: IUserRepository
    private let mediaRepository: IMediaRepository

    init(user: User, userRepository: IUserRepository = UserRepository(), mediaRepository: IMediaRepository = MediaRepository()) {
        self.displayName = user.displayName
        self.bio = user.bio
        self.selectedAvatarURL = user.avatarURL
        self.userRepository = userRepository
        self.mediaRepository = mediaRepository
    }

    /// The display name must contain something besides whitespace; bio may be empty.
    var canSubmit: Bool {
        !displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !state.isLoading
    }

    /// Reuses Module 5's mock "camera roll" catalog rather than a real photo picker —
    /// there's no real backend to upload to anyway.
    var avatarChoices: [MediaAsset] {
        (avatarChoicesState.value ?? []).filter { $0.kind == .image }
    }

    func loadAvatarChoices() async {
        guard !isPreview else { return }
        avatarChoicesState = .loading
        do {
            let assets = try await mediaRepository.availableAssets()
            avatarChoicesState = assets.isEmpty ? .empty : .loaded(assets)
        } catch {
            avatarChoicesState = .failed(error.asAppError)
        }
    }

    func selectAvatar(_ asset: MediaAsset) {
        selectedAvatarURL = asset.thumbnailURL
    }

    /// Saves trimmed name and bio plus the chosen avatar. Returns the updated user, or nil on failure (the error is left in `state`).
    func save() async -> User? {
        state = .loading
        do {
            let updated = try await userRepository.updateProfile(
                displayName: displayName.trimmingCharacters(in: .whitespacesAndNewlines),
                bio: bio.trimmingCharacters(in: .whitespacesAndNewlines),
                avatarURL: selectedAvatarURL
            )
            state = .loaded(updated)
            return updated
        } catch {
            state = .failed(error.asAppError)
            return nil
        }
    }
}

#if DEBUG
extension EditProfileViewModel {
    convenience init(previewScenario scenario: FormPreviewScenario) {
        self.init(user: PreviewData.currentUser)
        isPreview = true
        avatarChoicesState = .loaded(PreviewData.mediaAssets)
        switch scenario {
        case .empty: displayName = ""; bio = ""
        case .invalid: displayName = "   "
        case .filled: break
        case .submitting: state = .loading
        case .failed: state = .failed(PreviewData.error)
        }
    }
}
#endif
