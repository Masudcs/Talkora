import XCTest
@testable import Talkora
@testable import Core

@MainActor
final class NavControllerTests: XCTestCase {
    private final class A: BaseDestination {}
    private final class B: BaseDestination {}
    private final class C: BaseDestination {}
    private final class Item: BaseDestination {
        let id: String
        init(_ id: String) { self.id = id }
        override var parameterKey: String { id }
    }

    private func routes(_ nav: NavController) -> [String] { nav.navStack.map(\.route) }

    func testNavigateAndPop() {
        let nav = NavController()
        nav.navigateTo(A())
        nav.navigateTo(B())
        XCTAssertEqual(routes(nav), ["A", "B"])
        nav.popBackStack()
        XCTAssertEqual(routes(nav), ["A"])
        nav.popBackStack()
        nav.popBackStack() // no-op on empty
        XCTAssertTrue(nav.navStack.isEmpty)
    }

    func testLaunchSingleTopSkipsEqualTopOnly() {
        let nav = NavController()
        nav.navigateTo(Item("1"), launchSingleTop: true)
        nav.navigateTo(Item("1"), launchSingleTop: true)
        XCTAssertEqual(nav.navStack.count, 1)
        nav.navigateTo(Item("2"), launchSingleTop: true) // same route, different parameters
        XCTAssertEqual(nav.navStack.count, 2)
        nav.navigateTo(Item("2")) // without the flag duplicates are allowed
        XCTAssertEqual(nav.navStack.count, 3)
    }

    func testNavigateToMultiple() {
        let nav = NavController()
        nav.navigateTo([A(), B(), C()])
        XCTAssertEqual(routes(nav), ["A", "B", "C"])
    }

    func testPopUpToExclusiveAndInclusive() {
        let nav = NavController()
        nav.navigateTo([A(), B(), C()])
        nav.popUpTo(A.self)
        XCTAssertEqual(routes(nav), ["A"])

        nav.navigateTo([B(), C()])
        nav.popUpTo(B.self, inclusive: true)
        XCTAssertEqual(routes(nav), ["A"])
    }

    func testPopUpToMissingDestinationIsNoOp() {
        let nav = NavController()
        nav.navigateTo([A(), B()])
        nav.popUpTo(C.self)
        XCTAssertEqual(routes(nav), ["A", "B"])
    }

    func testPopUpToUsesMostRecentMatch() {
        let nav = NavController()
        nav.navigateTo([A(), B(), A(), C()])
        nav.popUpTo(A.self)
        XCTAssertEqual(routes(nav), ["A", "B", "A"])
    }

    func testNavigateWithPopUpTo() {
        let nav = NavController()
        nav.navigateTo([A(), B()])
        nav.navigateTo(C(), popUpTo: B.self, inclusive: true)
        XCTAssertEqual(routes(nav), ["A", "C"])

        nav.navigateTo([A(), B()], popUpTo: A.self)
        XCTAssertEqual(routes(nav), ["A", "A", "B"])
    }

    func testPopUpToRootAndCurrentDestination() {
        let nav = NavController()
        XCTAssertTrue(nav.currentDestination() is Destination.Root)
        nav.navigateTo([A(), B()])
        XCTAssertEqual(nav.currentDestination().route, "B")
        nav.popUpToRoot()
        XCTAssertTrue(nav.navStack.isEmpty)
        XCTAssertTrue(nav.currentDestination() is Destination.Root)
    }

    func testStackDescription() {
        let nav = NavController()
        XCTAssertEqual(nav.stackDescription, "Root")
        nav.navigateTo([A(), B()])
        XCTAssertEqual(nav.stackDescription, "Root > (1) A > (2) B")
    }
}
