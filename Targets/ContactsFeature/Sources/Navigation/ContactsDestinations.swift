import SwiftUI
import Core

/// Destinations pushed from the Contacts tab.
extension Destination {
    /// Search people by name or @username and send a contact request.
    final class SearchUsers: BaseDestination {
        override func getScreen(navController: NavController) -> AnyView {
            AnyView(SearchUsersScreen())
        }
    }

    /// Shows the current user's QR code for others to scan.
    final class MyQRCode: BaseDestination {
        override func getScreen(navController: NavController) -> AnyView {
            AnyView(MyQRCodeScreen())
        }
    }

    /// Simulated QR scanner (no camera); connects instantly.
    final class ScanQR: BaseDestination {
        override func getScreen(navController: NavController) -> AnyView {
            AnyView(ScanQRScreen())
        }
    }

    /// Address-book sync: lists device contacts and which of them are on Talkora.
    final class DeviceContacts: BaseDestination {
        override func getScreen(navController: NavController) -> AnyView {
            AnyView(DeviceContactsScreen())
        }
    }

    /// Pending contact requests to accept or decline.
    final class IncomingRequests: BaseDestination {
        override func getScreen(navController: NavController) -> AnyView {
            AnyView(IncomingRequestsScreen())
        }
    }
}
