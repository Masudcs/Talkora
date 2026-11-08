import Foundation

/// Sign-in, OTP and app-lock PIN endpoints. The OTP, login and PIN-verify calls are `requiresAuth: false` because they happen before any session exists. `setAppLockPIN(nil)` sends no `pin` field, which the mock backend treats as removing the PIN.
public enum AuthRoutes: EndpointConvertible {
    case requestOTP(phoneNumber: String)
    case resendOTP(challengeId: String)
    case verifyOTP(challengeId: String, code: String)
    case login(identifier: String, password: String)
    case completeProfile(userId: String, displayName: String)
    case setAppLockPIN(String?)
    case appLockStatus
    case verifyAppLockPIN(String)

    public var endpoint: Endpoint {
        switch self {
        case .requestOTP(let phoneNumber):
            return Endpoint(path: "/auth/otp/request", method: .post, body: PhoneBody(phoneNumber: phoneNumber), requiresAuth: false)
        case .resendOTP(let challengeId):
            return Endpoint(path: "/auth/otp/resend", method: .post, body: ChallengeBody(challengeId: challengeId), requiresAuth: false)
        case .verifyOTP(let challengeId, let code):
            return Endpoint(path: "/auth/otp/verify", method: .post, body: VerifyOTPBody(challengeId: challengeId, code: code), requiresAuth: false)
        case .login(let identifier, let password):
            return Endpoint(path: "/auth/login", method: .post, body: LoginBody(identifier: identifier, password: password), requiresAuth: false)
        case .completeProfile(let userId, let displayName):
            return Endpoint(path: "/users/\(userId)", method: .patch, body: DisplayNameBody(displayName: displayName))
        case .setAppLockPIN(let pin):
            return Endpoint(path: "/auth/pin", method: .put, body: PINBody(pin: pin))
        case .appLockStatus:
            return Endpoint(path: "/auth/pin-status")
        case .verifyAppLockPIN(let pin):
            return Endpoint(path: "/auth/pin-verify", method: .post, body: PINBody(pin: pin), requiresAuth: false)
        }
    }
}

// MARK: - Request bodies

/// Encodable request bodies for these routes. Optional fields that are `nil` are left out of the JSON and of the flattened `query`.
public extension AuthRoutes {
    struct PhoneBody: Encodable, Sendable { let phoneNumber: String }
    struct ChallengeBody: Encodable, Sendable { let challengeId: String }
    struct VerifyOTPBody: Encodable, Sendable { let challengeId: String; let code: String }
    struct LoginBody: Encodable, Sendable { let identifier: String; let password: String }
    struct DisplayNameBody: Encodable, Sendable { let displayName: String }
    struct PINBody: Encodable, Sendable { let pin: String? }
}
