@testable import Talkora
import Foundation
import XCTest
@testable import Core
@testable import Profile

@MainActor
final class ProfileViewModelTests: XCTestCase {
    private func makeUser(_ id: String, _ name: String = "User", bio: String = "", avatarURL: URL? = nil) -> User {
        User(id: id, displayName: name, handle: "@\(id)", avatarURL: avatarURL, status: .online, createdAt: Date(), bio: bio)
    }

    // MARK: - EditProfileViewModel

    private func makeEdit(user: User? = nil, users: StubUserRepository = StubUserRepository(), media: StubMediaRepository = StubMediaRepository()) -> EditProfileViewModel {
        EditProfileViewModel(user: user ?? makeUser("u1", "Ava", bio: "Hi"), userRepository: users, mediaRepository: media)
    }

    func test_editInit_copiesUserFields() {
        let url = URL(string: "https://example.com/a.png")
        let viewModel = makeEdit(user: makeUser("u1", "Ava", bio: "Hi", avatarURL: url))
        XCTAssertEqual(viewModel.displayName, "Ava")
        XCTAssertEqual(viewModel.bio, "Hi")
        XCTAssertEqual(viewModel.selectedAvatarURL, url)
    }

    func test_editCanSubmit_isFalse_whenNameBlank() {
        let viewModel = makeEdit()
        viewModel.displayName = " \n "
        XCTAssertFalse(viewModel.canSubmit)
    }

    func test_editLoadAvatarChoices_success_filtersToImages() async {
        let media = StubMediaRepository()
        media.availableAssetsResult = .success([
            MediaAsset(id: "a1", kind: .image, fileName: "a.jpg", thumbnailURL: nil, originalSizeBytes: 1, durationSeconds: nil),
            MediaAsset(id: "a2", kind: .video, fileName: "b.mp4", thumbnailURL: nil, originalSizeBytes: 1, durationSeconds: 3)
        ])
        let viewModel = makeEdit(media: media)

        await viewModel.loadAvatarChoices()

        XCTAssertEqual(viewModel.avatarChoices.map(\.id), ["a1"])
    }

    func test_editLoadAvatarChoices_empty_setsEmptyState() async {
        let viewModel = makeEdit()

        await viewModel.loadAvatarChoices()

        guard case .empty = viewModel.avatarChoicesState else {
            return XCTFail("Expected empty state")
        }
        XCTAssertTrue(viewModel.avatarChoices.isEmpty)
    }

    func test_editLoadAvatarChoices_failure_setsFailedState() async {
        let media = StubMediaRepository()
        media.availableAssetsResult = .failure(StubFailure.notConfigured)
        let viewModel = makeEdit(media: media)

        await viewModel.loadAvatarChoices()

        XCTAssertNotNil(viewModel.avatarChoicesState.error)
    }

    func test_editSelectAvatar_updatesSelectedURL() {
        let url = URL(string: "https://example.com/new.png")
        let viewModel = makeEdit()

        viewModel.selectAvatar(MediaAsset(id: "a1", kind: .image, fileName: "a.jpg", thumbnailURL: url, originalSizeBytes: 1, durationSeconds: nil))

        XCTAssertEqual(viewModel.selectedAvatarURL, url)
    }

    func test_editSave_success_returnsUpdatedUser() async {
        let users = StubUserRepository()
        users.updateProfileResult = .success(makeUser("u1", "Ava B", bio: "New"))
        let viewModel = makeEdit(users: users)
        viewModel.displayName = "  Ava B  "

        let result = await viewModel.save()

        XCTAssertEqual(result?.displayName, "Ava B")
        XCTAssertEqual(viewModel.state.value?.bio, "New")
    }

    func test_editSave_failure_returnsNilAndSetsFailed() async {
        let users = StubUserRepository()
        users.updateProfileResult = .failure(StubFailure.notConfigured)
        let viewModel = makeEdit(users: users)

        let result = await viewModel.save()

        XCTAssertNil(result)
        XCTAssertNotNil(viewModel.state.error)
    }

    // MARK: - ProfileViewModel

    func test_profileLoad_success_populatesUser() async {
        let users = StubUserRepository()
        users.currentUserResult = .success(makeUser("u1", "Ava"))
        let viewModel = ProfileViewModel(userRepository: users)

        await viewModel.load()

        XCTAssertEqual(viewModel.user?.id, "u1")
    }

    func test_profileLoad_failure_setsFailedAndNoUser() async {
        let users = StubUserRepository()
        users.currentUserResult = .failure(StubFailure.notConfigured)
        let viewModel = ProfileViewModel(userRepository: users)

        await viewModel.load()

        XCTAssertNil(viewModel.user)
        XCTAssertNotNil(viewModel.userState.error)
    }

    func test_profileHandleProfileSaved_replacesUser() {
        let viewModel = ProfileViewModel(userRepository: StubUserRepository())

        viewModel.handleProfileSaved(makeUser("u2", "Zed"))

        XCTAssertEqual(viewModel.user?.displayName, "Zed")
    }
}
