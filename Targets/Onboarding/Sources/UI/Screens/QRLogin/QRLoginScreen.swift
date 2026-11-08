import SwiftUI
import Core

/// QR sign-in placeholder: shows a static code and a button that simulates a successful scan, then pushes `ProfileSetup`.
struct QRLoginScreen: View {
    let navController: NavController
    @State private var viewModel: QRLoginViewModel

    init(navController: NavController, viewModel: QRLoginViewModel = QRLoginViewModel()) {
        self.navController = navController
        _viewModel = State(wrappedValue: viewModel)
    }

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "qrcode")
                .font(.system(size: 140))
                .foregroundStyle(Color.primary)
                .padding(24)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16))

            VStack(spacing: 4) {
                Text("Log in with QR code")
                    .font(Font.title2.weight(.semibold))
                Text("Open Talkora on a device where you're already signed in, then scan this code from Settings > Linked Devices.")
                    .font(Font.body)
                    .foregroundStyle(Color.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 24)

            if let error = viewModel.state.error {
                Text(error.userMessage)
                    .font(Font.caption)
                    .foregroundStyle(Color.red)
            }

            Spacer()

            if viewModel.state.isLoading {
                ProgressView()
            } else {
                Button("Simulate Successful Scan") {
                    Task {
                        await viewModel.simulateScan()
                        if case .loaded(let user) = viewModel.state {
                            navController.navigateTo(Destination.ProfileSetup(userId: user.id))
                        }
                    }
                }
                .font(Font.footnote)
                .foregroundStyle(Color.secondary)
                .padding(.bottom, 24)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
        .navigationTitle("QR Login")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#if DEBUG
#Preview("Ready") {
    NavigationStack { QRLoginScreen(navController: NavController(), viewModel: QRLoginViewModel(previewScenario: .empty)) }
}

#Preview("Scanning") {
    NavigationStack { QRLoginScreen(navController: NavController(), viewModel: QRLoginViewModel(previewScenario: .submitting)) }
}

#Preview("Error") {
    NavigationStack { QRLoginScreen(navController: NavController(), viewModel: QRLoginViewModel(previewScenario: .failed)) }
}
#endif
