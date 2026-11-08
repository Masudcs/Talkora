import Foundation

public protocol IPrivacyRepository: Sendable {
    func lastSeenVisibility() async throws -> LastSeenVisibility
    func setLastSeenVisibility(_ value: LastSeenVisibility) async throws -> LastSeenVisibility
    func blockedUsers() async throws -> [User]
    func isBlocked(_ userId: String) async throws -> Bool
    func blockUser(_ userId: String) async throws
    func unblockUser(_ userId: String) async throws
    func reportUser(_ userId: String, reason: String) async throws
}
