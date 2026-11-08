import Foundation
import Observation
import Core
import CommonUI
import Mock

/// Backs the Settings tab (`ProfileScreen`): current user, theme, sign-out and which sheets are showing.
@MainActor
@Observable
final class ProfileViewModel {
    /// Preview-only flag that makes `load()` a no-op so seeded state isn't overwritten. `@ObservationIgnored` because the UI never reads it.
    @ObservationIgnored private var isPreview = false
    private(set) var userState: LoadableState<User> = .idle
    var isEditPresented = false
    var isNotificationSettingsPresented = false
    var isPrivacyPresented = false

    private let userRepository: IUserRepository
    private let session: AuthSessionStore
    private let themeStore: ThemeStore

    init(userRepository: IUserRepository = UserRepository(), session: AuthSessionStore = .shared, themeStore: ThemeStore = .shared) {
        self.userRepository = userRepository
        self.session = session
        self.themeStore = themeStore
    }

    var theme: TalkoraTheme {
        themeStore.theme
    }

    func setTheme(_ theme: TalkoraTheme) {
        themeStore.setTheme(theme)
    }

    /// Clears the session; the app shell reacts by returning to onboarding.
    func signOut() {
        session.signOut()
    }

    var user: User? {
        userState.value
    }

    func load() async {
        guard !isPreview else { return }
        userState = .loading
        do {
            let user = try await userRepository.currentUser()
            userState = .loaded(user)
        } catch {
            userState = .failed(error.asAppError)
        }
    }

    /// Adopts the edited user directly so the header updates without refetching.
    func handleProfileSaved(_ user: User) {
        userState = .loaded(user)
    }
}

#if DEBUG
extension ProfileViewModel {
    convenience init(previewScenario scenario: PreviewScenario) {
        self.init(session: AuthSessionStore(defaults: PreviewData.defaults), themeStore: ThemeStore(defaults: PreviewData.defaults))
        isPreview = true
        switch scenario {
        case .loaded: userState = .loaded(PreviewData.currentUser)
        case .loading: userState = .loading
        case .empty: userState = .empty
        case .failed: userState = .failed(PreviewData.error)
        }
    }
}
#endif
