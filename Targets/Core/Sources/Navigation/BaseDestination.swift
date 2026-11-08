import SwiftUI

/// A navigation target. Each screen (or feature) declares its own subclass carrying the
/// parameters it needs, so features stay decoupled — no central route enum to grow — and
/// `NavController` can still walk the stack by `route` for `popUpTo`.
///
/// Two destinations are equal when they have the same `route` (class name) and the same
/// `parameterKey`, so `launchSingleTop` distinguishes `Thread(a)` from `Thread(b)`.
@MainActor
open class BaseDestination {
    /// Class name of the destination; `NavController.popUpTo` matches on it.
    public var route: String { String(describing: type(of: self)) }

    /// Override in subclasses that carry parameters, returning a stable string for them.
    open var parameterKey: String { "" }

    public init() {}

    /// The screen to show for this destination. `navController` is the stack it was pushed on.
    /// Every destination overrides this and builds its own screen, so the module that owns the
    /// destination is the one that owns the view.
    open func getScreen(navController: NavController) -> AnyView {
        fatalError("\(route) must override getScreen(navController:)")
    }

    /// The screen for presenting in a sheet or full-screen cover, which doesn't push further on
    /// a navigation stack.
    public final func presentedScreen() -> AnyView {
        getScreen(navController: NavController())
    }
}

/// Identity is `route` plus `parameterKey`, which is what `launchSingleTop` and `NavigationStack` use to compare destinations.
extension BaseDestination: @preconcurrency Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(route)
        hasher.combine(parameterKey)
    }

    public static func == (lhs: BaseDestination, rhs: BaseDestination) -> Bool {
        lhs.route == rhs.route && lhs.parameterKey == rhs.parameterKey
    }
}

/// Namespace for destinations. Features add theirs in an `extension Destination`.
public enum Destination {
    /// Placeholder for a stack's root screen (what `currentDestination()` returns when empty).
    /// Never pass this to a `NavController` navigation method.
    public final class Root: BaseDestination {}
}
