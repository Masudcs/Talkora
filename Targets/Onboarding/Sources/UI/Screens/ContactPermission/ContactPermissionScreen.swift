import SwiftUI
import Core
import CommonUI
import Mock

/// Improve: contact-sync permission is asked here — after profile setup, not before
/// account creation — and skipping never blocks progress into the app.
/// Both buttons currently just continue to `PINSetup`; no system contacts permission request is made here yet.
struct ContactPermissionScreen: View {
    let navController: NavController
    let userId: String

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "person.2.fill")
                .font(.system(size: 56))
                .foregroundStyle(Color.accentColor)

            VStack(spacing: 4) {
                Text("Find your friends")
                    .font(Font.title2.weight(.semibold))
                Text("Sync your contacts to see who's already on Talkora. You can change this anytime in Settings.")
                    .font(Font.body)
                    .foregroundStyle(Color.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 24)

            Spacer()

            VStack(spacing: 8) {
                TalkoraButton("Allow Access") {
                    navController.navigateTo(Destination.PINSetup(userId: userId))
                }
                Button("Not Now") {
                    navController.navigateTo(Destination.PINSetup(userId: userId))
                }
                .font(Font.headline)
                .foregroundStyle(Color.secondary)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
        .navigationTitle("Contacts")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden()
    }
}

#if DEBUG
#Preview("Contact permission") {
    NavigationStack { ContactPermissionScreen(navController: NavController(), userId: PreviewData.currentUser.id) }
}
#endif
