import SwiftUI
import Core

/// Full-width prominent button for primary actions.
public struct TalkoraButton: View {
    private let title: String
    private let action: () -> Void

    public init(_ title: String, action: @escaping () -> Void) {
        self.title = title
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            Text(title)
                .font(Font.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
        }
        .buttonStyle(.borderedProminent)
        .tint(Color.accentColor)
    }
}

#Preview {
    TalkoraButton("Continue", action: {})
        .padding()
}
