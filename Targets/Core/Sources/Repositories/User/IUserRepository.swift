import Foundation

public protocol IUserRepository: Sendable {
    func currentUser() async throws -> User
    func user(id: String) async throws -> User
    func allUsers() async throws -> [User]
    func updateProfile(displayName: String, bio: String, avatarURL: URL?) async throws -> User
}
