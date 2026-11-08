import Foundation
import Observation
import Core
import Mock

/// Backs `PrivacyScreen`: last-seen visibility, blocked contacts and app-lock settings. App-lock changes are mirrored into the shared `AppLockManager` so enforcement takes effect immediately.
@MainActor
@Observable
final class PrivacyViewModel {
    /// Preview-only flag that makes `load()` a no-op so seeded state isn't overwritten. `@ObservationIgnored` because the UI never reads it.
    @ObservationIgnored private var isPreview = false
    private(set) var lastSeen: LastSeenVisibility = .everyone
    private(set) var blockedUsersState: LoadableState<[User]> = .idle
    /// Whether a PIN is set. Changed only through `disableAppLock()` and `handlePINSaved()` so it stays in sync with `AppLockManager`.
    private(set) var isAppLockEnabled = false
    var isPINSheetPresented = false
    /// True while an unblock request runs; disables the Unblock buttons to prevent overlapping reloads.
    var isUnblocking = false

    private let privacyRepository: IPrivacyRepository
    private let authRepository: IAuthRepository
    private let appLock: AppLockManager

    init(privacyRepository: IPrivacyRepository = PrivacyRepository(), authRepository: IAuthRepository = AuthRepository(), appLock: AppLockManager = .shared) {
        self.privacyRepository = privacyRepository
        self.authRepository = authRepository
        self.appLock = appLock
    }

    /// The loaded blocked users, or empty in any other state.
    var blockedUsers: [User] {
        blockedUsersState.value ?? []
    }

    /// Loads app-lock status, last-seen setting and blocked users. The first two fall back to defaults (disabled, everyone) on error rather than surfacing it.
    func load() async {
        guard !isPreview else { return }
        isAppLockEnabled = (try? await authRepository.isAppLockEnabled()) ?? false
        lastSeen = (try? await privacyRepository.lastSeenVisibility()) ?? .everyone
        await reloadBlockedUsers()
    }

    private func reloadBlockedUsers() async {
        blockedUsersState = .loading
        do {
            let users = try await privacyRepository.blockedUsers()
            blockedUsersState = users.isEmpty ? .empty : .loaded(users)
        } catch {
            blockedUsersState = .failed(error.asAppError)
        }
    }

    /// Updates the setting; the displayed value only changes once the repository confirms, so a failed update leaves the picker unchanged.
    func setLastSeen(_ value: LastSeenVisibility) async {
        if let updated = try? await privacyRepository.setLastSeenVisibility(value) {
            lastSeen = updated
        }
    }

    /// Unblocks and then reloads the list; an unblock error is ignored and the reload shows the real state.
    func unblock(_ user: User) async {
        isUnblocking = true
        defer { isUnblocking = false }
        try? await privacyRepository.unblockUser(user.id)
        await reloadBlockedUsers()
    }

    /// The onboarding PIN sheet already handles set-vs-skip; this reuses the same
    /// repository call so re-enabling app lock from the Privacy hub sets a fresh PIN.
    /// Clearing the PIN (nil) is what turns app lock off. Local state is updated even if that call fails.
    func disableAppLock() async {
        try? await authRepository.setAppLockPIN(nil)
        isAppLockEnabled = false
        appLock.setEnabled(false)
    }

    /// Called after `SetAppLockPINSheet` saved a PIN (new or changed); turns enforcement on.
    func handlePINSaved() {
        isAppLockEnabled = true
        appLock.setEnabled(true)
    }

    /// Panic action: locks immediately, so the PIN is needed to get back in. The screen only enables it while app lock is on.
    func lockdownNow() {
        appLock.lockNow()
    }
}

#if DEBUG
extension PrivacyViewModel {
    convenience init(previewScenario scenario: PreviewScenario) {
        self.init(appLock: AppLockManager())
        isPreview = true
        isAppLockEnabled = scenario == .loaded
        blockedUsersState = scenario.state(PreviewData.blockedUsers)
    }
}
#endif
