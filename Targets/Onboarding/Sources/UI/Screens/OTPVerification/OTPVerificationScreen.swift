import SwiftUI
import Core
import CommonUI

/// Step 2 of phone sign-in: enter the 6-digit code. On success pushes `ProfileSetup`.
struct OTPVerificationScreen: View {
    let navController: NavController
    @State private var viewModel: OTPVerificationViewModel

    init(navController: NavController, challengeId: String, phoneNumber: String, debugHint: String?, viewModel: OTPVerificationViewModel? = nil) {
        self.navController = navController
        _viewModel = State(wrappedValue: viewModel ?? OTPVerificationViewModel(
            challengeId: challengeId,
            phoneNumber: phoneNumber,
            debugHint: debugHint
        ))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Enter the code")
                    .font(Font.title2.weight(.semibold))
                Text("We sent a 6-digit code to \(viewModel.phoneNumber).")
                    .font(Font.body)
                    .foregroundStyle(Color.secondary)
                if let debugHint = viewModel.debugHint {
                    Text(debugHint)
                        .font(Font.caption)
                        .foregroundStyle(Color.accentColor)
                }
            }

            TextField("123456", text: $viewModel.code)
                .keyboardType(.numberPad)
                .textContentType(.oneTimeCode)
                .font(Font.title2.weight(.semibold))
                .padding()
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                // Caps input at 6 characters (autofill via `.oneTimeCode` can paste more).
                .onChange(of: viewModel.code) {
                    if viewModel.code.count > 6 {
                        viewModel.code = String(viewModel.code.prefix(6))
                    }
                }

            if let error = viewModel.verifyState.error {
                Text(error.userMessage)
                    .font(Font.caption)
                    .foregroundStyle(Color.red)
            }

            // Improve: OTP delivery failures are handled visibly — resend and a fallback
            // are always one tap away instead of leaving the user stuck on a code that
            // never arrives.
            HStack {
                Button("Didn't get a code? Resend") {
                    Task { await viewModel.resend() }
                }
                .font(Font.footnote)
                if viewModel.resendState.isLoading {
                    ProgressView().controlSize(.mini)
                }
            }
            .foregroundStyle(Color.secondary)

            Spacer()

            if viewModel.verifyState.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
            } else {
                TalkoraButton("Verify") {
                    Task {
                        await viewModel.verify()
                        if case .loaded(let user) = viewModel.verifyState {
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
        .navigationTitle("Verify")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#if DEBUG
#Preview("Empty") {
    NavigationStack { OTPVerificationScreen(navController: NavController(), challengeId: "preview-challenge", phoneNumber: "+8801712345678", debugHint: "Demo code: 123456", viewModel: OTPVerificationViewModel(previewScenario: .empty)) }
}

#Preview("Invalid") {
    NavigationStack { OTPVerificationScreen(navController: NavController(), challengeId: "preview-challenge", phoneNumber: "+8801712345678", debugHint: "Demo code: 123456", viewModel: OTPVerificationViewModel(previewScenario: .invalid)) }
}

#Preview("Filled") {
    NavigationStack { OTPVerificationScreen(navController: NavController(), challengeId: "preview-challenge", phoneNumber: "+8801712345678", debugHint: "Demo code: 123456", viewModel: OTPVerificationViewModel(previewScenario: .filled)) }
}

#Preview("Submitting") {
    NavigationStack { OTPVerificationScreen(navController: NavController(), challengeId: "preview-challenge", phoneNumber: "+8801712345678", debugHint: "Demo code: 123456", viewModel: OTPVerificationViewModel(previewScenario: .submitting)) }
}

#Preview("Error") {
    NavigationStack { OTPVerificationScreen(navController: NavController(), challengeId: "preview-challenge", phoneNumber: "+8801712345678", debugHint: "Demo code: 123456", viewModel: OTPVerificationViewModel(previewScenario: .failed)) }
}
#endif
