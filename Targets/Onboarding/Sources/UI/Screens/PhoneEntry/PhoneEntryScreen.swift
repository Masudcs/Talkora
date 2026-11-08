import SwiftUI
import Core
import CommonUI

/// Step 1 of phone sign-in. Pushes `OTPVerification` once the code request succeeds.
struct PhoneEntryScreen: View {
    let navController: NavController
    @State private var viewModel: PhoneEntryViewModel

    init(navController: NavController, viewModel: PhoneEntryViewModel = PhoneEntryViewModel()) {
        self.navController = navController
        _viewModel = State(wrappedValue: viewModel)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Enter your phone number")
                    .font(Font.title2.weight(.semibold))
                Text("Enter your 11-digit mobile number. We'll send you a verification code. Standard rates may apply.")
                    .font(Font.body)
                    .foregroundStyle(Color.secondary)
            }

            TextField("01XXXXXXXXX", text: $viewModel.phoneNumber)
                .keyboardType(.phonePad)
                .textContentType(.telephoneNumber)
                .font(Font.body)
                .padding()
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))

            if let message = viewModel.validationMessage {
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
                TalkoraButton("Send Code") {
                    Task {
                        await viewModel.sendCode()
                        if case .loaded(let challenge) = viewModel.state {
                            navController.navigateTo(Destination.OTPVerification(challengeId: challenge.id, phoneNumber: challenge.phoneNumber, debugHint: challenge.debugHint))
                        }
                    }
                }
                .disabled(!viewModel.canSubmit)
                .opacity(viewModel.canSubmit ? 1 : 0.5)
            }
        }
        .padding(24)
        .background(Color(.systemBackground))
        .navigationTitle("Phone Number")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#if DEBUG
#Preview("Empty") {
    NavigationStack { PhoneEntryScreen(navController: NavController(), viewModel: PhoneEntryViewModel(previewScenario: .empty)) }
}

#Preview("Invalid") {
    NavigationStack { PhoneEntryScreen(navController: NavController(), viewModel: PhoneEntryViewModel(previewScenario: .invalid)) }
}

#Preview("Filled") {
    NavigationStack { PhoneEntryScreen(navController: NavController(), viewModel: PhoneEntryViewModel(previewScenario: .filled)) }
}

#Preview("Submitting") {
    NavigationStack { PhoneEntryScreen(navController: NavController(), viewModel: PhoneEntryViewModel(previewScenario: .submitting)) }
}

#Preview("Error") {
    NavigationStack { PhoneEntryScreen(navController: NavController(), viewModel: PhoneEntryViewModel(previewScenario: .failed)) }
}
#endif
