import SwiftUI
import Core

/// Entry point the app shell embeds while the user is signed out. Owns the flow's own `NavigationStack`.
/// Step order: Welcome -> (PhoneEntry -> OTPVerification | UsernameLogin | QRLogin) -> ProfileSetup
/// -> ContactPermission -> PINSetup. Completing PINSetup (set or skip) marks onboarding done, which
/// makes the shell dismiss this flow.
public struct OnboardingFlowScreen: View {
    // Owned here (not passed in) so every onboarding screen pushes onto this one stack.
    @State private var navController = NavController()

    public init() {}

    public var body: some View {
        NavigationStack(path: $navController.navStack) {
            WelcomeScreen(navController: navController)
                .navigationDestination(for: BaseDestination.self) { destination in
                    destination.getScreen(navController: navController)
                }
        }
    }
}

#if DEBUG
#Preview("Onboarding flow") {
    OnboardingFlowScreen()
}
#endif
