import SwiftUI
import Core

/// Full-screen placeholder for a loaded-but-empty list (`LoadableState.empty`): an icon over a title.
public struct EmptyStateView: View {
    private let title: String
    private let systemImage: String

    public init(title: String, systemImage: String = "tray") {
        self.title = title
        self.systemImage = systemImage
    }

    public var body: some View {
        VStack(spacing: 16) {
            Image(systemName: systemImage)
                .font(.system(size: 36))
                .foregroundStyle(Color.secondary)
            Text(title)
                .font(Font.body)
                .foregroundStyle(Color.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}

#Preview {
    EmptyStateView(title: "No conversations yet")
}
