import SwiftUI
import Core

/// Full-screen spinner for `LoadableState.loading`.
public struct LoadingView: View {
    public init() {}

    public var body: some View {
        VStack(spacing: 16) {
            ProgressView("Loading")
                .controlSize(.large)
//            Text("Loading…")
//                .font(Font.caption)
//                .foregroundStyle(Color.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}

#Preview {
    LoadingView()
}
