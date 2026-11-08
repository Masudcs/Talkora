@testable import Talkora
import Foundation
@testable import Core

final class StubAuthRepository: IAuthRepository {
    private(set) var requestOTPCallCount = 0
    private(set) var lastRequestedPhoneNumber: String?
    private(set) var loginCallCount = 0
    private(set) var lastLoginIdentifier: String?
    var requestOTPResult: Result<OTPChallenge, Error> = .failure(StubFailure.notConfigured)
    var resendOTPResult: Result<OTPChallenge, Error> = .failure(StubFailure.notConfigured)
    var verifyOTPResult: Result<User, Error> = .failure(StubFailure.notConfigured)
    var loginResult: Result<User, Error> = .failure(StubFailure.notConfigured)
    var completeProfileResult: Result<User, Error> = .failure(StubFailure.notConfigured)
    var setAppLockPINResult: Result<Void, Error> = .success(())
    var isAppLockEnabledResult: Result<Bool, Error> = .success(false)
    var verifyAppLockPINResult: Result<Bool, Error> = .success(false)

    func requestOTP(phoneNumber: String) async throws -> OTPChallenge {
        requestOTPCallCount += 1
        lastRequestedPhoneNumber = phoneNumber
        return try requestOTPResult.get()
    }

    func resendOTP(challengeId: String) async throws -> OTPChallenge {
        try resendOTPResult.get()
    }

    func verifyOTP(challengeId: String, code: String) async throws -> User {
        try verifyOTPResult.get()
    }

    func login(identifier: String, password: String) async throws -> User {
        loginCallCount += 1
        lastLoginIdentifier = identifier
        return try loginResult.get()
    }

    func completeProfile(userId: String, displayName: String) async throws -> User {
        try completeProfileResult.get()
    }

    func setAppLockPIN(_ pin: String?) async throws {
        try setAppLockPINResult.get()
    }

    func isAppLockEnabled() async throws -> Bool {
        try isAppLockEnabledResult.get()
    }

    func verifyAppLockPIN(_ pin: String) async throws -> Bool {
        try verifyAppLockPINResult.get()
    }
}
