import XCTest

/// Launches the app on the stubbed backend (real Moya stack, canned `stubs.json` responses) and
/// checks the chat list renders from it.
final class StubbedBackendUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func test_stubbedBackend_showsConversationsFromStubCatalog() {
        let app = XCUIApplication()
        app.launchArguments = [
            "-talkora-backend", "stubbed",
            "-talkora.session.currentUserId", "u1",
        ]
        app.launch()

        XCTAssertTrue(app.navigationBars["Chats"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["Amara Chen"].waitForExistence(timeout: 10))
    }
}

/// Forces a route to fail on the stubbed backend and checks the screen shows its error state.
final class StubbedFailureUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func test_failingConversationsRoute_showsRetryableErrorState() {
        let app = XCUIApplication()
        app.launchArguments = [
            "-talkora-backend", "stubbed",
            "-talkora-stub-fail", "GET /conversations=500",
            "-talkora.session.currentUserId", "u1",
        ]
        app.launch()

        XCTAssertTrue(app.staticTexts["Our servers had a problem. Please try again shortly."].waitForExistence(timeout: 10))
        XCTAssertTrue(app.buttons["Try Again"].exists)
        XCTAssertFalse(app.staticTexts["Amara Chen"].exists)
    }
}
