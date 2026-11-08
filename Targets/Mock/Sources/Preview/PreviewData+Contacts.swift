#if DEBUG
import Foundation
import Core

public extension PreviewData {
    /// A mix of contacts matched to Talkora users and contacts not on the app.
    static let deviceContacts: [DeviceContact] = DeviceContactFixtures.seed.map { $0.toDomain() }

    /// Pending contact requests from other users to the current user.
    static var incomingRequests: [ContactRequest] {
        users.filter { $0.id != currentUser.id }.prefix(3).enumerated().map { index, user in
            ContactRequest(
                id: "preview-request-\(index)",
                fromUserId: user.id,
                toUserId: currentUser.id,
                status: .pending,
                createdAt: Date(timeIntervalSinceNow: -Double(index + 1) * 3600)
            )
        }
    }
}
#endif
