import SwiftUI
import Core
import CommonUI
import Mock

/// Onboarding step after sign-in: choose a display name. Back is hidden so the user can't return to the sign-in screens; continues to `ContactPermission`.
struct ProfileSetupScreen: View {
    let navController: NavController
    @State private var viewModel: ProfileSetupViewModel

    init(navController: NavController, userId: String, viewModel: ProfileSetupViewModel? = nil) {
        self.navController = navController
        _viewModel = State(wrappedValue: viewModel ?? ProfileSetupViewModel(userId: userId))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Set up your profile")
                    .font(Font.title2.weight(.semibold))
                Text("This is how you'll appear to your contacts.")
                    .font(Font.body)
                    .foregroundStyle(Color.secondary)
            }

            HStack {
                Spacer()
                TalkoraAvatar(name: viewModel.displayName.isEmpty ? "?" : viewModel.displayName, size: 88)
                Spacer()
            }

            TextField("Your name", text: $viewModel.displayName)
                .font(Font.body)
                .padding()
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))

            if let error = viewModel.state.error {
                Text(error.userMessage)
                    .font(Font.caption)
                    .foregroundStyle(Color.red)
            }

            Spacer()

            if viewModel.state.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
            } else {
                TalkoraButton("Continue") {
                    Task {
                        await viewModel.save()
                        if case .loaded(let user) = viewModel.state {
                            navController.navigateTo(Destination.ContactPermission(userId: user.id))
                        }
                    }
                }
                .disabled(!viewModel.canSubmit)
                .opacity(viewModel.canSubmit ? 1 : 0.5)
            }
        }
        .padding(24)
        .background(Color(.systemBackground))
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden()
    }
}

#if DEBUG
#Preview("Empty") {
    NavigationStack { ProfileSetupScreen(navController: NavController(), userId: PreviewData.currentUser.id, viewModel: ProfileSetupViewModel(previewScenario: .empty)) }
}

#Preview("Filled") {
    NavigationStack { ProfileSetupScreen(navController: NavController(), userId: PreviewData.currentUser.id, viewModel: ProfileSetupViewModel(previewScenario: .filled)) }
}

#Preview("Saving") {
    NavigationStack { ProfileSetupScreen(navController: NavController(), userId: PreviewData.currentUser.id, viewModel: ProfileSetupViewModel(previewScenario: .submitting)) }
}

#Preview("Error") {
    NavigationStack { ProfileSetupScreen(navController: NavController(), userId: PreviewData.currentUser.id, viewModel: ProfileSetupViewModel(previewScenario: .failed)) }
}
#endif
