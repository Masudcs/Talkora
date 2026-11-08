import Foundation
import Observation


/// Tracks whether the user has completed onboarding, persisted across launches so a
/// relaunch doesn't force the user back through phone/OTP every time. Deliberately a
/// thin app-shell concern, not a "feature": `AppShellView` switches between onboarding and the
/// main app on `isAuthenticated`, `PINSetupViewModel` signs in, and `ProfileViewModel` signs out.
/// App-lock gating is layered on top of it by `AppLockManager`. Use `AuthSessionStore.shared`.
@MainActor
@Observable
public final class AuthSessionStore {
    /// The app-wide session. ViewModels default to it; tests pass an isolated store instead.
    public static let shared = AuthSessionStore()

    /// True when a user id is stored; restored from `UserDefaults` at launch.
    public private(set) var isAuthenticated: Bool
    public private(set) var currentUserId: String?

    private let defaults: UserDefaults
    private static let userIdKey = "talkora.session.currentUserId"

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let storedId = defaults.string(forKey: Self.userIdKey)
        self.currentUserId = storedId
        self.isAuthenticated = storedId != nil
    }

    /// Marks the user as signed in and persists the id.
    public func completeOnboarding(userId: String) {
        currentUserId = userId
        isAuthenticated = true
        defaults.set(userId, forKey: Self.userIdKey)
    }

    /// Clears the persisted id, which sends `AppShellView` back to onboarding.
    public func signOut() {
        currentUserId = nil
        isAuthenticated = false
        defaults.removeObject(forKey: Self.userIdKey)
    }
}
