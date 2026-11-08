@testable import Talkora
import Foundation
@testable import Core

final class StubPrivacyRepository: IPrivacyRepository {
    var lastSeenVisibilityResult: Result<LastSeenVisibility, Error> = .failure(StubFailure.notConfigured)
    var setLastSeenVisibilityResult: Result<LastSeenVisibility, Error> = .failure(StubFailure.notConfigured)
    var blockedUsersResult: Result<[User], Error> = .success([])
    var isBlockedResult: Result<Bool, Error> = .success(false)
    var blockUserResult: Result<Void, Error> = .success(())
    var unblockUserResult: Result<Void, Error> = .success(())
    var reportUserResult: Result<Void, Error> = .success(())

    func lastSeenVisibility() async throws -> LastSeenVisibility {
        try lastSeenVisibilityResult.get()
    }

    func setLastSeenVisibility(_ value: LastSeenVisibility) async throws -> LastSeenVisibility {
        try setLastSeenVisibilityResult.get()
    }

    func blockedUsers() async throws -> [User] {
        try blockedUsersResult.get()
    }

    func isBlocked(_ userId: String) async throws -> Bool {
        try isBlockedResult.get()
    }

    func blockUser(_ userId: String) async throws {
        try blockUserResult.get()
    }

    func unblockUser(_ userId: String) async throws {
        try unblockUserResult.get()
    }

    func reportUser(_ userId: String, reason: String) async throws {
        try reportUserResult.get()
    }
}
