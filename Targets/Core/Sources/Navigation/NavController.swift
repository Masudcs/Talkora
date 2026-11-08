import Observation
import SwiftUI

/// Drives one `NavigationStack`. Bind `navStack` to the stack's path and resolve screens with
/// `.navigationDestination(for: BaseDestination.self)`.
///
/// Each `NavigationStack` owns its own controller (one per tab / flow, hosted by
/// each screen's `NavigationStack`), so stacks never interfere. Pass the instance down to screens that need to
/// navigate. (One shared stack with the tabs inside it was tried, but it drops the tab screens'
/// `navigationTitle`, toolbar and search field.) Sheets and full-screen covers manage their own
/// presentation locally.
///
/// Tested in `NavControllerTests`.
@MainActor
@Observable
public final class NavController {
    /// Bottom-to-top stack of pushed destinations, bound to the `NavigationStack` path. Empty means the root screen is showing.
    public var navStack: [BaseDestination] = []

    public init() {}

    /// Pushes a destination.
    /// - Parameter launchSingleTop: skip the push if the top of the stack is an equal destination.
    public func navigateTo(_ destination: BaseDestination, launchSingleTop: Bool = false) {
        assert(!(destination is Destination.Root), "Use popUpToRoot() to return to the root screen.")
        if launchSingleTop, navStack.last == destination { return }
        navStack.append(destination)
    }

    /// Pushes several destinations at once, in order.
    public func navigateTo(_ destinations: [BaseDestination]) {
        assert(!destinations.contains { $0 is Destination.Root }, "Use popUpToRoot() to return to the root screen.")
        navStack.append(contentsOf: destinations)
    }

    /// Pops up to `popUpTo` (see `popUpTo(_:inclusive:)`), then pushes `destinations`.
    public func navigateTo(_ destinations: [BaseDestination], popUpTo: BaseDestination.Type, inclusive: Bool = false) {
        self.popUpTo(popUpTo, inclusive: inclusive)
        navigateTo(destinations)
    }

    /// Pops up to `popUpTo` (see `popUpTo(_:inclusive:)`), then pushes `destination`.
    public func navigateTo(
        _ destination: BaseDestination,
        launchSingleTop: Bool = false,
        popUpTo: BaseDestination.Type,
        inclusive: Bool = false
    ) {
        self.popUpTo(popUpTo, inclusive: inclusive)
        navigateTo(destination, launchSingleTop: launchSingleTop)
    }

    /// Pops the top destination — the back button.
    public func popBackStack() {
        guard !navStack.isEmpty else { return }
        navStack.removeLast()
    }

    /// Pops every destination above the most recent one of type `destination`.
    /// With `inclusive`, that destination is popped too. No-op if it isn't on the stack.
    public func popUpTo(_ destination: BaseDestination.Type, inclusive: Bool = false) {
        let route = String(describing: destination)
        guard let index = navStack.lastIndex(where: { $0.route == route }) else { return }
        navStack.removeLast(navStack.count - index - (inclusive ? 0 : 1))
    }

    public func popUpToRoot() {
        navStack.removeAll()
    }

    /// The top destination, or `Destination.Root` when the stack is empty.
    public func currentDestination() -> BaseDestination {
        navStack.last ?? Destination.Root()
    }

    /// Human-readable stack, e.g. `Root > (1) CreateGroup > (2) ChatThread`. For logging.
    public var stackDescription: String {
        (["Root"] + navStack.enumerated().map { "(\($0.offset + 1)) \($0.element.route)" }).joined(separator: " > ")
    }
}
