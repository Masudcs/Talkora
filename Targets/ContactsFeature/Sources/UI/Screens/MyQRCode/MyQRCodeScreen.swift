import SwiftUI
import Core
import CommonUI

/// Renders the current user's QR code (generated on-device by `QRCodeGenerator`) with their name and handle.
struct MyQRCodeScreen: View {
    @State private var viewModel: MyQRCodeViewModel

    init(viewModel: MyQRCodeViewModel = MyQRCodeViewModel()) {
        _viewModel = State(wrappedValue: viewModel)
    }

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            if let user = viewModel.state.value, let payload = viewModel.qrPayload, let image = QRCodeGenerator.image(for: payload) {
                Image(uiImage: image)
                    .interpolation(.none)
                    .resizable()
                    .frame(width: 220, height: 220)
                Text(user.displayName)
                    .font(Font.headline)
                Text(user.handle)
                    .font(Font.caption)
                    .foregroundStyle(Color.secondary)
            } else if let error = viewModel.state.error {
                ErrorStateView(message: error.userMessage, isRetryable: error.isRetryable) {
                    Task { await viewModel.load() }
                }
            } else {
                ProgressView()
            }
            Text("Let someone scan this code to instantly connect — no request needed.")
                .font(Font.caption)
                .foregroundStyle(Color.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
            Spacer()
        }
        .padding(24)
        .navigationTitle("My QR Code")
        .navigationBarTitleDisplayMode(.inline)
        .task { await viewModel.load() }
    }
}

#if DEBUG
#Preview("Loaded") {
    NavigationStack { MyQRCodeScreen(viewModel: MyQRCodeViewModel(previewScenario: .loaded)) }
}

#Preview("Loading") {
    NavigationStack { MyQRCodeScreen(viewModel: MyQRCodeViewModel(previewScenario: .loading)) }
}

#Preview("Error") {
    NavigationStack { MyQRCodeScreen(viewModel: MyQRCodeViewModel(previewScenario: .failed)) }
}
#endif
