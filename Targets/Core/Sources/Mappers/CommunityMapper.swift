import Foundation

/// Unknown linked-item kinds fall back to `.group`.
public extension CommunityDTO {
    func toDomain() -> Community {
        Community(
            id: id,
            title: title,
            description: description,
            ownerId: ownerId,
            memberIds: memberIds,
            linkedItems: linkedItems.map {
                CommunityLinkedItem(itemId: $0.itemId, kind: CommunityLinkedItemKind(rawValue: $0.kind) ?? .group, title: $0.title)
            },
            createdAt: ISO8601.date(from: createdAt)
        )
    }
}
