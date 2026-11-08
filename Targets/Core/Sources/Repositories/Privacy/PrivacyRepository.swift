import Foundation

/// Last-seen, blocking and reporting, over `APIClientProtocol` — behaves the same against the mock, stubbed and live backends.
public final class PrivacyRepository: IPrivacyRepository {
    private let api: APIClientProtocol

    public init(api: APIClientProtocol = APIClientProvider.shared.client) {
        self.api = api
    }

    public func lastSeenVisibility() async throws -> LastSeenVisibility {
        let value: String = try await api.request(PrivacyRoutes.lastSeen)
        return LastSeenVisibility(rawValue: value) ?? .everyone
    }

    public func setLastSeenVisibility(_ value: LastSeenVisibility) async throws -> LastSeenVisibility {
        let updated: String = try await api.request(
            PrivacyRoutes.setLastSeen(value: value.rawValue)
        )
        return LastSeenVisibility(rawValue: updated) ?? .everyone
    }

    public func blockedUsers() async throws -> [User] {
        let dtos: [UserDTO] = try await api.request(PrivacyRoutes.blockedUsers)
        return dtos.map { $0.toDomain() }
    }

    public func isBlocked(_ userId: String) async throws -> Bool {
        try await api.request(PrivacyRoutes.blockedStatus(userId: userId))
    }

    public func blockUser(_ userId: String) async throws {
        try await api.requestVoid(PrivacyRoutes.block(userId: userId))
    }

    public func unblockUser(_ userId: String) async throws {
        try await api.requestVoid(PrivacyRoutes.unblock(userId: userId))
    }

    public func reportUser(_ userId: String, reason: String) async throws {
        try await api.requestVoid(PrivacyRoutes.report(userId: userId, reason: reason))
    }
}
