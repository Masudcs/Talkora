import Foundation
import Observation


/// Real app-lock enforcement layered on top of `AuthSessionStore`. The PIN itself was already
/// stored during Module 1 onboarding (`IAuthRepository.setAppLockPIN`) but never actually gated
/// anything — this closes that gap, and also backs the Module 9 "Lockdown Now" panic action.
@MainActor
@Observable
public final class AppLockManager {
    /// The app-wide lock state, shared by the shell, the lock screen and the Privacy settings.
    public static let shared = AppLockManager()

    /// Whether a PIN is set.
    public private(set) var isEnabled = false
    /// Whether the lock screen should currently cover the app.
    public private(set) var isLocked = false

    public init() {}

    /// Reads PIN status from the backend. When a PIN exists the app starts locked; failures count as "not enabled".
    public func refreshLockState(authRepository: IAuthRepository) async {
        let enabled = (try? await authRepository.isAppLockEnabled()) ?? false
        isEnabled = enabled
        isLocked = enabled
    }

    /// Call after the PIN is set or removed; disabling also unlocks.
    public func setEnabled(_ enabled: Bool) {
        isEnabled = enabled
        if !enabled {
            isLocked = false
        }
    }

    public func lockIfEnabled() {
        guard isEnabled else { return }
        isLocked = true
    }

    /// Locks unconditionally (the "Lockdown Now" action).
    public func lockNow() {
        isLocked = true
    }

    /// Returns true and unlocks when the PIN matches; a wrong PIN or a backend error leaves the app locked.
    public func unlock(pin: String, authRepository: IAuthRepository) async -> Bool {
        guard let isValid = try? await authRepository.verifyAppLockPIN(pin), isValid else {
            return false
        }
        isLocked = false
        return true
    }
}
