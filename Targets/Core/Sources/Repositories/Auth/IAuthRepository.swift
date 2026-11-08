import Foundation

/// Sign-in flow: OTP challenge, password login, profile completion and the app-lock PIN.
public protocol IAuthRepository: Sendable {
    func requestOTP(phoneNumber: String) async throws -> OTPChallenge
    func resendOTP(challengeId: String) async throws -> OTPChallenge
    func verifyOTP(challengeId: String, code: String) async throws -> User
    func login(identifier: String, password: String) async throws -> User
    func completeProfile(userId: String, displayName: String) async throws -> User
    /// Pass `nil` to remove the PIN.
    func setAppLockPIN(_ pin: String?) async throws
    /// Module 9 closes the loop Module 1 opened: the PIN is now actually enforced, not
    /// just stored. Backs both app-launch/background auto-lock and the panic "Lockdown Now"
    /// action's unlock screen.
    func isAppLockEnabled() async throws -> Bool
    func verifyAppLockPIN(_ pin: String) async throws -> Bool
}
