@testable import Talkora
import Foundation
@testable import Core

final class StubUserRepository: IUserRepository {
    var currentUserResult: Result<User, Error> = .failure(StubFailure.notConfigured)
    var userResult: Result<User, Error> = .failure(StubFailure.notConfigured)
    var allUsersResult: Result<[User], Error> = .success([])
    var updateProfileResult: Result<User, Error> = .failure(StubFailure.notConfigured)

    func currentUser() async throws -> User {
        try currentUserResult.get()
    }

    func user(id: String) async throws -> User {
        try userResult.get()
    }

    func allUsers() async throws -> [User] {
        try allUsersResult.get()
    }

    func updateProfile(displayName: String, bio: String, avatarURL: URL?) async throws -> User {
        try updateProfileResult.get()
    }
}

enum StubFailure: Error {
    case notConfigured
}
