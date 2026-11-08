import XCTest
@testable import Talkora
@testable import Core
@testable import Messaging
@testable import Onboarding

@MainActor
final class AppDestinationsTests: XCTestCase {
    func testDestinationsWithSameParametersAreEqual() {
        XCTAssertEqual(Destination.ChatThread(conversationId: "1"), Destination.ChatThread(conversationId: "1"))
        XCTAssertEqual(Destination.CreateGroup(), Destination.CreateGroup())
        XCTAssertEqual(Set<BaseDestination>([Destination.ChatThread(conversationId: "1"), Destination.ChatThread(conversationId: "1")]).count, 1)
    }

    func testDestinationsWithDifferentParametersOrTypesAreNotEqual() {
        XCTAssertNotEqual(Destination.ChatThread(conversationId: "1"), Destination.ChatThread(conversationId: "2"))
        XCTAssertNotEqual(Destination.GroupInfo(conversationId: "1"), Destination.AddMembers(conversationId: "1"))
        XCTAssertNotEqual(Destination.ProfileSetup(userId: "u"), Destination.PINSetup(userId: "u"))
    }

    func testLaunchSingleTopDistinguishesConversations() {
        let nav = NavController()
        nav.navigateTo(Destination.ChatThread(conversationId: "1"), launchSingleTop: true)
        nav.navigateTo(Destination.ChatThread(conversationId: "1"), launchSingleTop: true)
        nav.navigateTo(Destination.ChatThread(conversationId: "2"), launchSingleTop: true)
        XCTAssertEqual(nav.navStack.count, 2)
    }

    /// Create Group replaces itself with the new thread, so Back returns to the chat list.
    func testCreateGroupIsReplacedByThread() {
        let nav = NavController()
        nav.navigateTo(Destination.CreateGroup())
        nav.navigateTo(Destination.ChatThread(conversationId: "g1"), popUpTo: Destination.CreateGroup.self, inclusive: true)
        XCTAssertEqual(nav.navStack, [Destination.ChatThread(conversationId: "g1")])
    }

    /// Leaving a group from Group Info returns to the chat list.
    func testLeavingGroupPopsToRoot() {
        let nav = NavController()
        nav.navigateTo([Destination.ChatThread(conversationId: "g1"), Destination.GroupInfo(conversationId: "g1")])
        nav.popUpToRoot()
        XCTAssertTrue(nav.navStack.isEmpty)
    }
}
