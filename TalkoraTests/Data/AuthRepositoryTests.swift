@testable import Talkora
import XCTest
@testable import Core
@testable import Mock

final class AuthRepositoryTests: XCTestCase {
    private let testEnvironment = AppEnvironment(
        name: .development,
        apiBaseURL: URL(string: "https://test.local")!,
        isLoggingEnabled: false,
        displayName: "Test"
    )

    private func makeRepository(store: MockDataStore) -> AuthRepository {
        AuthRepository(api: MockAPIClient(store: store, environment: testEnvironment), environment: testEnvironment, demoOTPCode: MockAuthConstants.demoOTPCode)
    }

    func test_requestOTP_thenVerifyWithCorrectCode_succeeds() async throws {
        let store = MockDataStore()
        let repository = makeRepository(store: store)

        let challenge = try await repository.requestOTP(phoneNumber: "+15551234567")
        XCTAssertEqual(challenge.debugHint, "Demo code: 123456")

        let user = try await repository.verifyOTP(challengeId: challenge.id, code: "123456")
        XCTAssertEqual(user.id, "u1")
    }

    func test_verifyOTP_withWrongCode_throwsInvalidCode() async throws {
        let store = MockDataStore()
        let repository = makeRepository(store: store)
        let challenge = try await repository.requestOTP(phoneNumber: "+15551234567")

        do {
            _ = try await repository.verifyOTP(challengeId: challenge.id, code: "000000")
            XCTFail("Expected invalidCode error")
        } catch let error as AuthError {
            XCTAssertEqual(error, .invalidCode)
        }
    }

    func test_resendOTP_returnsRefreshedChallengeUsableForVerification() async throws {
        let store = MockDataStore()
        let repository = makeRepository(store: store)
        let original = try await repository.requestOTP(phoneNumber: "+15551234567")

        let resent = try await repository.resendOTP(challengeId: original.id)
        let user = try await repository.verifyOTP(challengeId: resent.id, code: "123456")
        XCTAssertEqual(user.id, "u1")
    }

    func test_login_withAnyCredentials_resolvesDemoUser() async throws {
        let store = MockDataStore()
        let repository = makeRepository(store: store)

        let user = try await repository.login(identifier: "anything", password: "anything")
        XCTAssertEqual(user.id, "u1")
    }

    func test_completeProfile_updatesDisplayName() async throws {
        let store = MockDataStore()
        let repository = makeRepository(store: store)

        let user = try await repository.completeProfile(userId: "u1", displayName: "New Name")
        XCTAssertEqual(user.displayName, "New Name")

        let refetched = try await repository.login(identifier: "anything", password: "anything")
        XCTAssertEqual(refetched.displayName, "New Name")
    }
}

extension AuthError: Equatable {
    public static func == (lhs: AuthError, rhs: AuthError) -> Bool {
        switch (lhs, rhs) {
        case (.invalidCode, .invalidCode), (.challengeExpired, .challengeExpired), (.invalidCredentials, .invalidCredentials):
            return true
        default:
            return false
        }
    }
}
