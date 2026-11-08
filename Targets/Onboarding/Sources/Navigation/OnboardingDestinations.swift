import SwiftUI
import Core

/// Destinations in the onboarding flow's `NavigationStack`, resolved by `OnboardingFlowScreen`.
extension Destination {
    /// First step of the phone sign-in path (Welcome -> PhoneEntry -> OTPVerification).
    final class PhoneEntry: BaseDestination {
        override func getScreen(navController: NavController) -> AnyView {
            AnyView(PhoneEntryScreen(navController: navController))
        }
    }

    /// Second step of phone sign-in. `challengeId` comes from `PhoneEntry`; `debugHint` is the non-production demo-code hint (nil in production).
    final class OTPVerification: BaseDestination {
        let challengeId: String
        let phoneNumber: String
        let debugHint: String?
        init(challengeId: String, phoneNumber: String, debugHint: String?) {
            self.challengeId = challengeId
            self.phoneNumber = phoneNumber
            self.debugHint = debugHint
        }
        // `parameterKey` identifies the destination in the nav stack: one challenge, one screen.
        override var parameterKey: String { challengeId }
        override func getScreen(navController: NavController) -> AnyView {
            AnyView(OTPVerificationScreen(navController: navController, challengeId: challengeId, phoneNumber: phoneNumber, debugHint: debugHint))
        }
    }

    /// Alternative to phone sign-in: username/email plus password. Success continues to `ProfileSetup`.
    final class UsernameLogin: BaseDestination {
        override func getScreen(navController: NavController) -> AnyView {
            AnyView(UsernameLoginScreen(navController: navController))
        }
    }

    /// Placeholder QR sign-in; see `QRLoginViewModel` for what the simulated scan does.
    final class QRLogin: BaseDestination {
        override func getScreen(navController: NavController) -> AnyView {
            AnyView(QRLoginScreen(navController: navController))
        }
    }

    /// Display-name step, reached after any successful sign-in (OTP, username or QR).
    final class ProfileSetup: BaseDestination {
        let userId: String
        init(userId: String) { self.userId = userId }
        override var parameterKey: String { userId }
        override func getScreen(navController: NavController) -> AnyView {
            AnyView(ProfileSetupScreen(navController: navController, userId: userId))
        }
    }

    /// Contact-sync prompt, after `ProfileSetup`. Always continues to `PINSetup`.
    final class ContactPermission: BaseDestination {
        let userId: String
        init(userId: String) { self.userId = userId }
        override var parameterKey: String { userId }
        override func getScreen(navController: NavController) -> AnyView {
            AnyView(ContactPermissionScreen(navController: navController, userId: userId))
        }
    }

    /// Final onboarding step (optional app-lock PIN). Has no push target: finishing it ends onboarding via `AuthSessionStore`, and the app shell swaps this flow out.
    final class PINSetup: BaseDestination {
        let userId: String
        init(userId: String) { self.userId = userId }
        override var parameterKey: String { userId }
        override func getScreen(navController: NavController) -> AnyView {
            AnyView(PINSetupScreen(userId: userId))
        }
    }
}
