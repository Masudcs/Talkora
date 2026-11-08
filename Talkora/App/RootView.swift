import SwiftUI
import Core
import CommonUI
import Messaging
import Stories
import ContactsFeature
import Calls
import Profile

/// Post-auth entry point. Hosts the top-level tabs — `Messaging` for chats,
/// `Stories` for status updates, `Calls` for the call log,
/// `ContactsFeature` for discovery and `Profile` for settings. Each tab screen owns its
/// navigation (a `NavigationStack` and, where it pushes screens, a `NavController`), so a tab's own title, toolbar and search stay intact.
struct RootView: View {
    var body: some View {
        TabView {
            ConversationListScreen()
                .tabItem { Label("Chats", systemImage: "bubble.left.and.bubble.right.fill") }
            StatusScreen()
                .tabItem { Label("Status", systemImage: "circle.dashed") }
            ContactsScreen()
                .tabItem { Label("Contacts", systemImage: "person.2.fill") }
            CallLogScreen()
                .tabItem { Label("Calls", systemImage: "phone.fill") }
            ProfileScreen()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
    }
}
