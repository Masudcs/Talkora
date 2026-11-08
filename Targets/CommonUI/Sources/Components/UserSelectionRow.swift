import SwiftUI
import Core

/// A user row with a trailing checkmark, used by every "pick people" list.
public struct UserSelectionRow: View {
    public let user: User
    public let isSelected: Bool
    public let onToggle: () -> Void

    public var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 16) {
                TalkoraAvatar(name: user.displayName, size: 36)
                VStack(alignment: .leading, spacing: 2) {
                    Text(user.displayName)
                        .foregroundStyle(Color.primary)
                    Text(user.handle)
                        .font(Font.caption)
                        .foregroundStyle(Color.secondary)
                }
                Spacer()
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? Color.accentColor : Color.secondary)
            }
        }
        .buttonStyle(.plain)
    }

    public init(user: User, isSelected: Bool, onToggle: @escaping () -> Void) {
        self.user = user
        self.isSelected = isSelected
        self.onToggle = onToggle
    }
}
