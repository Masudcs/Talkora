import SwiftUI
import Core

/// Shared across Chat/Group (and, later, Channel) message views — one component so
/// reaction rendering/toggling stays consistent everywhere it's used.
public struct ReactionBarView: View {
    public let reactions: [MessageReaction]
    public let currentUserId: String
    /// Called with the tapped emoji; the caller adds or removes the current user's reaction.
    public let onToggle: (String) -> Void

    public var body: some View {
        if !reactions.isEmpty {
            HStack(spacing: 4) {
                ForEach(reactions.sorted { $0.emoji < $1.emoji }) { reaction in
                    let isMine = reaction.userIds.contains(currentUserId)
                    Button {
                        onToggle(reaction.emoji)
                    } label: {
                        HStack(spacing: 3) {
                            Text(reaction.emoji)
                            Text("\(reaction.userIds.count)")
                                .font(.caption2.bold())
                                .foregroundStyle(isMine ? Color.accentColor : Color.secondary)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(isMine ? Color.accentColor.opacity(0.15) : Color(.secondarySystemBackground))
                        .clipShape(Capsule())
                        .overlay(Capsule().strokeBorder(isMine ? Color.accentColor : .clear, lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    public init(reactions: [MessageReaction], currentUserId: String, onToggle: @escaping (String) -> Void) {
        self.reactions = reactions
        self.currentUserId = currentUserId
        self.onToggle = onToggle
    }
}
