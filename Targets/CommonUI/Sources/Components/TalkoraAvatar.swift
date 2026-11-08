import SwiftUI
import Core

/// Circular avatar showing up to two initials of `name` on a tinted background. There is no image loading: avatars are initials only.
public struct TalkoraAvatar: View {
    private let initials: String
    private let size: CGFloat

    public init(name: String, size: CGFloat = 44) {
        self.initials = Self.initials(from: name)
        self.size = size
    }

    public var body: some View {
        Circle()
            .fill(Color.accentColor.opacity(0.15))
            .overlay(
                Text(initials)
                    .font(.system(size: size * 0.4, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.accentColor)
            )
            .frame(width: size, height: size)
    }

    private static func initials(from name: String) -> String {
        let parts = name.split(separator: " ")
        let letters = parts.prefix(2).compactMap { $0.first }
        return String(letters).uppercased()
    }
}

#Preview {
    TalkoraAvatar(name: "Amara Chen")
}
