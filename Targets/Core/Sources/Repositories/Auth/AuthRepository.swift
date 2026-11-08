import Foundation

/// Sign-in, OTP and app-lock PIN, over `APIClientProtocol` — behaves the same against the mock, stubbed and live backends.
public final class AuthRepository: IAuthRepository {
    private let api: APIClientProtocol
    private let environment: AppEnvironment
    private let demoOTPCode: String?

    /// `demoOTPCode` is shown as a hint on non-production OTP challenges (the mock backend accepts a fixed code).
    public init(api: APIClientProtocol = APIClientProvider.shared.client, environment: AppEnvironment = .current, demoOTPCode: String? = DemoAuth.otpCode) {
        self.api = api
        self.environment = environment
        self.demoOTPCode = demoOTPCode
    }

    public func requestOTP(phoneNumber: String) async throws -> OTPChallenge {
        let dto: OTPChallengeDTO = try await api.request(
            AuthRoutes.requestOTP(phoneNumber: phoneNumber)
        )
        return dto.toDomain(debugHint: debugHint)
    }

    public func resendOTP(challengeId: String) async throws -> OTPChallenge {
        let dto: OTPChallengeDTO = try await api.request(
            AuthRoutes.resendOTP(challengeId: challengeId)
        )
        return dto.toDomain(debugHint: debugHint)
    }

    /// Any failure, including network errors, is reported as `AuthError.invalidCode`.
    public func verifyOTP(challengeId: String, code: String) async throws -> User {
        do {
            let dto: UserDTO = try await api.request(
                AuthRoutes.verifyOTP(challengeId: challengeId, code: code)
            )
            return dto.toDomain()
        } catch {
            throw AuthError.invalidCode
        }
    }

    /// Any failure, including network errors, is reported as `AuthError.invalidCredentials`.
    public func login(identifier: String, password: String) async throws -> User {
        do {
            let dto: UserDTO = try await api.request(
                AuthRoutes.login(identifier: identifier, password: password)
            )
            return dto.toDomain()
        } catch {
            throw AuthError.invalidCredentials
        }
    }

    public func completeProfile(userId: String, displayName: String) async throws -> User {
        let dto: UserDTO = try await api.request(
            AuthRoutes.completeProfile(userId: userId, displayName: displayName)
        )
        return dto.toDomain()
    }

    public func setAppLockPIN(_ pin: String?) async throws {
        try await api.requestVoid(
            AuthRoutes.setAppLockPIN(pin)
        )
    }

    public func isAppLockEnabled() async throws -> Bool {
        try await api.request(AuthRoutes.appLockStatus)
    }

    public func verifyAppLockPIN(_ pin: String) async throws -> Bool {
        try await api.request(AuthRoutes.verifyAppLockPIN(pin))
    }

    private var debugHint: String? {
        guard environment.name != .production, let demoOTPCode else { return nil }
        return "Demo code: \(demoOTPCode)"
    }
}
