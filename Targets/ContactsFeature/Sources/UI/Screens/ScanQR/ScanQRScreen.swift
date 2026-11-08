import SwiftUI
import Core

/// Demo QR scanner: there is no camera capture, so the user picks who they are "scanning" from a list. Real scanning would need camera permission handling here.
struct ScanQRScreen: View {
    @State private var viewModel: ScanQRViewModel

    init(viewModel: ScanQRViewModel = ScanQRViewModel()) {
        _viewModel = State(wrappedValue: viewModel)
    }

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "qrcode.viewfinder")
                .font(.system(size: 90))
                .foregroundStyle(Color.secondary)
                .padding(24)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16))

            if let connected = viewModel.connectedUser {
                Text("Connected with \(connected.displayName) 🎉")
                    .foregroundStyle(Color.accentColor)
            } else {
                Text("Point your camera at a Talkora QR code. For this demo, pick who you're \"scanning\":")
                    .font(Font.caption)
                    .foregroundStyle(Color.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                List(viewModel.candidates) { user in
                    Button(user.displayName) {
                        Task { await viewModel.simulateScan(user) }
                    }
                }
                .listStyle(.plain)
            }
        }
        .padding(.top, 24)
        .navigationTitle("Scan QR Code")
        .navigationBarTitleDisplayMode(.inline)
        .task { await viewModel.load() }
    }
}

#if DEBUG
#Preview("Candidates") {
    NavigationStack { ScanQRScreen(viewModel: ScanQRViewModel(previewScenario: .loaded)) }
}

#Preview("No Candidates") {
    NavigationStack { ScanQRScreen(viewModel: ScanQRViewModel(previewScenario: .empty)) }
}

#Preview("Connected") {
    NavigationStack { ScanQRScreen(viewModel: ScanQRViewModel(previewScenario: .failed)) }
}
#endif
