import SwiftUI
import Core
import CommonUI
import Onboarding
import Privacy

/// App-level switcher: shows the onboarding flow until a session exists, then the main app —
/// gated behind an app-lock screen when Module 9's PIN lock is enabled.
struct AppShellView: View {
    private let session = AuthSessionStore.shared
    private let appLock = AppLockManager.shared
    private let themeStore = ThemeStore.shared
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        Group {
            if session.isAuthenticated {
                if appLock.isLocked {
                    AppLockScreen()
                } else {
                    RootView()
                }
            } else {
                OnboardingFlowScreen()
            }
        }
        .preferredColorScheme(themeStore.theme.colorScheme)
        .task(id: session.isAuthenticated) {
            guard session.isAuthenticated else { return }
            await appLock.refreshLockState(authRepository: AuthRepository())
        }
        .onChange(of: scenePhase) { _, newPhase in
            guard newPhase == .background, session.isAuthenticated else { return }
            appLock.lockIfEnabled()
        }
    }
}
