import SwiftUI
import Core

/// A list row that pushes a screen via `NavController`. Looks like a `NavigationLink` row
/// (label plus a trailing chevron) but navigates through the shared stack instead of owning a link.
public struct PushRowButton<Label: View>: View {
    public let action: () -> Void
    @ViewBuilder public let label: () -> Label

    public var body: some View {
        Button(action: action) {
            HStack {
                label()
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    public init(action: @escaping () -> Void, @ViewBuilder label: @escaping () -> Label) {
        self.action = action
        self.label = label
    }
}
