@testable import Talkora
import Foundation
import XCTest
@testable import Core
@testable import Privacy

private func makeUser(_ id: String, _ name: String = "User") -> User {
    User(id: id, displayName: name, handle: "@\(id)", avatarURL: nil, status: .online, createdAt: Date())
}

@MainActor
final class PrivacyViewModelTests: XCTestCase {
    private func makeViewModel(privacy: StubPrivacyRepository, auth: StubAuthRepository = StubAuthRepository(),
                               appLock: AppLockManager = AppLockManager()) -> PrivacyViewModel {
        PrivacyViewModel(privacyRepository: privacy, authRepository: auth, appLock: appLock)
    }

    func test_load_success_populatesSettingsAndBlockedUsers() async {
        let privacy = StubPrivacyRepository()
        privacy.lastSeenVisibilityResult = .success(.nobody)
        privacy.blockedUsersResult = .success([makeUser("bob")])
        let auth = StubAuthRepository()
        auth.isAppLockEnabledResult = .success(true)
        let viewModel = makeViewModel(privacy: privacy, auth: auth)

        await viewModel.load()

        XCTAssertEqual(viewModel.lastSeen, .nobody)
        XCTAssertTrue(viewModel.isAppLockEnabled)
        XCTAssertEqual(viewModel.blockedUsers.map(\.id), ["bob"])
    }

    func test_load_withNoBlockedUsers_setsEmpty() async {
        let viewModel = makeViewModel(privacy: StubPrivacyRepository())

        await viewModel.load()

        guard case .empty = viewModel.blockedUsersState else {
            return XCTFail("Expected .empty, got \(viewModel.blockedUsersState)")
        }
        XCTAssertEqual(viewModel.lastSeen, .everyone)
        XCTAssertFalse(viewModel.isAppLockEnabled)
    }

    func test_load_blockedUsersFailure_setsFailed() async {
        let privacy = StubPrivacyRepository()
        privacy.blockedUsersResult = .failure(StubFailure.notConfigured)
        let viewModel = makeViewModel(privacy: privacy)

        await viewModel.load()

        XCTAssertNotNil(viewModel.blockedUsersState.error)
    }

    func test_setLastSeen_success_updatesValue() async {
        let privacy = StubPrivacyRepository()
        privacy.setLastSeenVisibilityResult = .success(.nobody)
        let viewModel = makeViewModel(privacy: privacy)

        await viewModel.setLastSeen(.nobody)

        XCTAssertEqual(viewModel.lastSeen, .nobody)
    }

    func test_setLastSeen_failure_keepsPreviousValue() async {
        let viewModel = makeViewModel(privacy: StubPrivacyRepository())

        await viewModel.setLastSeen(.nobody)

        XCTAssertEqual(viewModel.lastSeen, .everyone)
    }

    func test_unblock_reloadsBlockedUsersAndResetsFlag() async {
        let privacy = StubPrivacyRepository()
        privacy.blockedUsersResult = .success([])
        let viewModel = makeViewModel(privacy: privacy)

        await viewModel.unblock(makeUser("bob"))

        XCTAssertFalse(viewModel.isUnblocking)
        guard case .empty = viewModel.blockedUsersState else {
            return XCTFail("Expected .empty, got \(viewModel.blockedUsersState)")
        }
    }

    func test_handlePINSaved_enablesAppLock() {
        let appLock = AppLockManager()
        let viewModel = makeViewModel(privacy: StubPrivacyRepository(), appLock: appLock)

        viewModel.handlePINSaved()

        XCTAssertTrue(viewModel.isAppLockEnabled)
        XCTAssertTrue(appLock.isEnabled)
    }

    func test_disableAppLock_disablesAndUnlocks() async {
        let appLock = AppLockManager()
        let viewModel = makeViewModel(privacy: StubPrivacyRepository(), appLock: appLock)
        viewModel.handlePINSaved()
        viewModel.lockdownNow()
        XCTAssertTrue(appLock.isLocked)

        await viewModel.disableAppLock()

        XCTAssertFalse(viewModel.isAppLockEnabled)
        XCTAssertFalse(appLock.isEnabled)
        XCTAssertFalse(appLock.isLocked)
    }
}
