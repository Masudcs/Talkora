import SwiftUI
import Core

/// A `NavigationStack` driven by `navController` that resolves every `BaseDestination` pushed on it.
/// Hosts each tab and flow, so screens only call `navController.navigateTo(Destination.X())`.
public struct NavigationHost<Content: View>: View {
    @Bindable public var navController: NavController
    @ViewBuilder public let content: () -> Content

    public var body: some View {
        NavigationStack(path: $navController.navStack) {
            content()
                .navigationDestination(for: BaseDestination.self) { destination in
                    destination.getScreen(navController: navController)
                }
        }
    }

    public init(navController: NavController, @ViewBuilder content: @escaping () -> Content) {
        self.navController = navController
        self.content = content
    }
}
