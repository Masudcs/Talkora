import SwiftUI
import Core
import CommonUI
import Mock

/// Uncommon feature (Signal): optional PIN app-lock, set up as the final onboarding step.
/// Back is hidden: it is the last step, left only via Set PIN or Skip.
struct PINSetupScreen: View {
    @State private var viewModel: PINSetupViewModel

    init(userId: String, viewModel: PINSetupViewModel? = nil) {
        _viewModel = State(wrappedValue: viewModel ?? PINSetupViewModel(userId: userId))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Set a PIN")
                    .font(Font.title2.weight(.semibold))
                Text("Adds a lock screen PIN and helps recover your account if you lose your device.")
                    .font(Font.body)
                    .foregroundStyle(Color.secondary)
            }

            SecureField("4-digit PIN", text: $viewModel.pin)
                .keyboardType(.numberPad)
                .font(Font.title2.weight(.semibold))
                .padding()
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .onChange(of: viewModel.pin) {
                    viewModel.pinChanged()
                }

            SecureField("Confirm PIN", text: $viewModel.confirmPin)
                .keyboardType(.numberPad)
                .font(Font.title2.weight(.semibold))
                .padding()
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .onChange(of: viewModel.confirmPin) {
                    viewModel.confirmPinChanged()
                }

            if viewModel.pinsMismatch {
                Text("PINs don't match.")
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
                VStack(spacing: 8) {
                    TalkoraButton("Set PIN") {
                        Task { await viewModel.savePIN() }
                    }
                    .disabled(!viewModel.canSubmit)
                    .opacity(viewModel.canSubmit ? 1 : 0.5)

                    Button("Skip") {
                        Task { await viewModel.skip() }
                    }
                    .font(Font.headline)
                    .foregroundStyle(Color.secondary)
                }
            }
        }
        .padding(24)
        .background(Color(.systemBackground))
        .navigationTitle("App Lock")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden()
    }
}

#if DEBUG
#Preview("Empty") {
    NavigationStack { PINSetupScreen(userId: PreviewData.currentUser.id, viewModel: PINSetupViewModel(previewScenario: .empty)) }
}

#Preview("Mismatch") {
    NavigationStack { PINSetupScreen(userId: PreviewData.currentUser.id, viewModel: PINSetupViewModel(previewScenario: .invalid)) }
}

#Preview("Filled") {
    NavigationStack { PINSetupScreen(userId: PreviewData.currentUser.id, viewModel: PINSetupViewModel(previewScenario: .filled)) }
}

#Preview("Saving") {
    NavigationStack { PINSetupScreen(userId: PreviewData.currentUser.id, viewModel: PINSetupViewModel(previewScenario: .submitting)) }
}

#Preview("Error") {
    NavigationStack { PINSetupScreen(userId: PreviewData.currentUser.id, viewModel: PINSetupViewModel(previewScenario: .failed)) }
}
#endif
