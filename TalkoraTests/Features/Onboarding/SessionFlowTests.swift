@testable import Talkora
import Foundation
import XCTest
@testable import Core
@testable import CommonUI
@testable import Onboarding
@testable import Profile

/// Sign-in, sign-out and theme changes used to live in Views; they're ViewModel behavior now.
@MainActor
final class SessionFlowTests: XCTestCase {
    private func makeDefaults() -> UserDefaults {
        UserDefaults(suiteName: "session-flow-tests-\(UUID().uuidString)") ?? .standard
    }

    // MARK: PIN setup completes onboarding

    func test_pinSetup_saveSuccess_signsTheUserIn() async {
        let session = AuthSessionStore(defaults: makeDefaults())
        let viewModel = PINSetupViewModel(userId: "u7", repository: StubAuthRepository(), session: session)
        viewModel.pin = "1234"
        viewModel.confirmPin = "1234"

        await viewModel.savePIN()

        XCTAssertTrue(session.isAuthenticated)
        XCTAssertEqual(session.currentUserId, "u7")
    }

    func test_pinSetup_skipSuccess_signsTheUserIn() async {
        let session = AuthSessionStore(defaults: makeDefaults())
        let viewModel = PINSetupViewModel(userId: "u7", repository: StubAuthRepository(), session: session)

        await viewModel.skip()

        XCTAssertTrue(session.isAuthenticated)
    }

    func test_pinSetup_failure_doesNotSignTheUserIn() async {
        let stub = StubAuthRepository()
        stub.setAppLockPINResult = .failure(StubFailure.notConfigured)
        let session = AuthSessionStore(defaults: makeDefaults())
        let viewModel = PINSetupViewModel(userId: "u7", repository: stub, session: session)
        viewModel.pin = "1234"
        viewModel.confirmPin = "1234"

        await viewModel.savePIN()

        XCTAssertFalse(session.isAuthenticated)
        XCTAssertNotNil(viewModel.state.error)
    }

    // MARK: Profile owns sign-out and theme

    func test_profile_signOut_clearsTheSession() {
        let session = AuthSessionStore(defaults: makeDefaults())
        session.completeOnboarding(userId: "u1")
        let viewModel = ProfileViewModel(userRepository: StubUserRepository(), session: session, themeStore: ThemeStore(defaults: makeDefaults()))

        viewModel.signOut()

        XCTAssertFalse(session.isAuthenticated)
        XCTAssertNil(session.currentUserId)
    }

    func test_profile_setTheme_updatesAndPersistsTheStore() {
        let defaults = makeDefaults()
        let themeStore = ThemeStore(defaults: defaults)
        let viewModel = ProfileViewModel(userRepository: StubUserRepository(), session: AuthSessionStore(defaults: makeDefaults()), themeStore: themeStore)
        XCTAssertEqual(viewModel.theme, .system)

        viewModel.setTheme(.dark)

        XCTAssertEqual(viewModel.theme, .dark)
        XCTAssertEqual(ThemeStore(defaults: defaults).theme, .dark)
    }

    // MARK: Shared instances

    func test_sharedInstances_areSingletons() {
        XCTAssertTrue(AuthSessionStore.shared === AuthSessionStore.shared)
        XCTAssertTrue(AppLockManager.shared === AppLockManager.shared)
        XCTAssertTrue(ThemeStore.shared === ThemeStore.shared)
    }
}
