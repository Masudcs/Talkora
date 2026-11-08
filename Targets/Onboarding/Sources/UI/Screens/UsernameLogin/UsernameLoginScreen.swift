import SwiftUI
import Core
import CommonUI

/// Sign-in with username or email plus password, as an alternative to phone/OTP. Success pushes `ProfileSetup`.
struct UsernameLoginScreen: View {
    let navController: NavController
    @State private var viewModel: UsernameLoginViewModel

    init(navController: NavController, viewModel: UsernameLoginViewModel = UsernameLoginViewModel()) {
        self.navController = navController
        _viewModel = State(wrappedValue: viewModel)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Sign in")
                    .font(Font.title2.weight(.semibold))
                Text("No phone number needed.")
                    .font(Font.body)
                    .foregroundStyle(Color.secondary)
                Text("Demo mode: any username/email and password works.")
                    .font(Font.caption)
                    .foregroundStyle(Color.accentColor)
            }

            VStack(spacing: 8) {
                TextField("Username or email", text: $viewModel.identifier)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .keyboardType(.emailAddress)
                    .textContentType(.username)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                SecureField("Password", text: $viewModel.password)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            if let message = viewModel.identifierMessage {
                Text(message)
                    .font(Font.caption)
                    .foregroundStyle(Color.red)
            }

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
                TalkoraButton("Log In") {
                    Task {
                        await viewModel.login()
                        if case .loaded(let user) = viewModel.state {
                            navController.navigateTo(Destination.ProfileSetup(userId: user.id))
                        }
                    }
                }
                .disabled(!viewModel.canSubmit)
                .opacity(viewModel.canSubmit ? 1 : 0.5)
            }
        }
        .padding(24)
        .background(Color(.systemBackground))
        .navigationTitle("Sign In")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#if DEBUG
#Preview("Empty") {
    NavigationStack { UsernameLoginScreen(navController: NavController(), viewModel: UsernameLoginViewModel(previewScenario: .empty)) }
}

#Preview("Invalid") {
    NavigationStack { UsernameLoginScreen(navController: NavController(), viewModel: UsernameLoginViewModel(previewScenario: .invalid)) }
}

#Preview("Filled") {
    NavigationStack { UsernameLoginScreen(navController: NavController(), viewModel: UsernameLoginViewModel(previewScenario: .filled)) }
}

#Preview("Submitting") {
    NavigationStack { UsernameLoginScreen(navController: NavController(), viewModel: UsernameLoginViewModel(previewScenario: .submitting)) }
}

#Preview("Error") {
    NavigationStack { UsernameLoginScreen(navController: NavController(), viewModel: UsernameLoginViewModel(previewScenario: .failed)) }
}
#endif
