import XCTest

/// Smoke test for the Chat1to1 feature itself — skips onboarding (already verified as
/// part of Module 1) by seeding an authenticated session via launch argument, since
/// `-key value` launch arguments are automatically registered into `UserDefaults.standard`
/// (the NSArgumentDomain), matching exactly what `AuthSessionStore` reads on launch.
final class ChatThreadUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func test_openConversation_sendMessage_appearsInThread() {
        let app = XCUIApplication()
        app.launchArguments = ["-talkora.session.currentUserId", "u1"]
        app.launch()

        XCTAssertTrue(app.navigationBars["Chats"].waitForExistence(timeout: 5))
        let conversationRow = app.staticTexts["Amara Chen"]
        XCTAssertTrue(conversationRow.waitForExistence(timeout: 5))
        XCTAssertTrue(waitUntilHittable(conversationRow), "Conversation row never became tappable")
        conversationRow.tap()

        let messageField = app.textFields["Message"]
        XCTAssertTrue(messageField.waitForExistence(timeout: 15), "Chat thread never opened")
        XCTAssertTrue(waitUntilHittable(messageField, timeout: 10), "Message field never became tappable")
        focus(messageField)
        messageField.typeText("Hello from UI test")
        app.buttons["chatSendButton"].tap()

        XCTAssertTrue(app.staticTexts["Hello from UI test"].waitForExistence(timeout: 10))
    }

    // MARK: - Helpers

    /// Waits for the element to be on screen and tappable, instead of sleeping a fixed time
    /// while a push/sheet animation finishes.
    private func waitUntilHittable(_ element: XCUIElement, timeout: TimeInterval = 5) -> Bool {
        let hittable = NSPredicate(format: "isHittable == true")
        let expectation = XCTNSPredicateExpectation(predicate: hittable, object: element)
        return XCTWaiter().wait(for: [expectation], timeout: timeout) == .completed
    }

    /// Taps until the field actually has keyboard focus. A single tap right after a navigation
    /// transition can land before the field is ready, which makes `typeText` fail with
    /// "Neither element nor any descendant has keyboard focus".
    private func focus(_ field: XCUIElement, attempts: Int = 3, file: StaticString = #filePath, line: UInt = #line) {
        let focused = NSPredicate(format: "hasKeyboardFocus == true")
        for _ in 0..<attempts {
            field.tap()
            let expectation = XCTNSPredicateExpectation(predicate: focused, object: field)
            if XCTWaiter().wait(for: [expectation], timeout: 2) == .completed { return }
        }
        XCTFail("Field never received keyboard focus after \(attempts) taps", file: file, line: line)
    }
}
