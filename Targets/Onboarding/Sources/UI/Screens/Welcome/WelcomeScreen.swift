import SwiftUI
import Core
import CommonUI

/// Root of the onboarding stack: picks the sign-in method (phone, username/email, QR).
struct WelcomeScreen: View {
    let navController: NavController

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            VStack(spacing: 8) {
                Image(systemName: "bubble.left.and.bubble.right.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(Color.accentColor)
                Text("Talkora")
                    .font(Font.largeTitle.bold())
                    .foregroundStyle(Color.primary)
                Text("Simple. Secure. Fast messaging.")
                    .font(Font.body)
                    .foregroundStyle(Color.secondary)
            }

            Spacer()

            VStack(spacing: 8) {
                TalkoraButton("Continue with Phone Number") {
                    navController.navigateTo(Destination.PhoneEntry())
                }
                Button("Continue with Username or Email") {
                    navController.navigateTo(Destination.UsernameLogin())
                }
                .font(Font.headline)

                Button {
                    navController.navigateTo(Destination.QRLogin())
                } label: {
                    Label("Scan QR Code", systemImage: "qrcode.viewfinder")
                }
                .font(Font.footnote)
                .foregroundStyle(Color.secondary)
                .padding(.top, 8)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}

#Preview {
    WelcomeScreen(navController: NavController())
}
