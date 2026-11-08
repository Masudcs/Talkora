import Foundation

public extension DeviceContactDTO {
    func toDomain() -> DeviceContact {
        DeviceContact(id: id, name: name, phoneNumber: phoneNumber, matchedUserId: matchedUserId)
    }
}

/// Unknown status values fall back to `.pending`.
public extension ContactRequestDTO {
    func toDomain() -> ContactRequest {
        ContactRequest(
            id: id,
            fromUserId: fromUserId,
            toUserId: toUserId,
            status: ContactRequestStatus(rawValue: status) ?? .pending,
            createdAt: ISO8601.date(from: createdAt)
        )
    }
}
