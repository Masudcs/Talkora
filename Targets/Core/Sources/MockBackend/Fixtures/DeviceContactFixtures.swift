import Foundation

/// Simulates a phone's address book. Matches are hardcoded directly (rather than
/// cross-referencing phone numbers on `UserDTO`) since this is a mock-only concept.
public enum DeviceContactFixtures {
    public static let seed: [DeviceContactDTO] = [
        DeviceContactDTO(id: "dc1", name: "Amara Chen", phoneNumber: "+1 555 010 2001", matchedUserId: "u2"),
        DeviceContactDTO(id: "dc2", name: "Diego Fernández", phoneNumber: "+1 555 010 2002", matchedUserId: "u3"),
        DeviceContactDTO(id: "dc3", name: "Priya Nair", phoneNumber: "+1 555 010 2003", matchedUserId: "u4"),
        DeviceContactDTO(id: "dc4", name: "Mom", phoneNumber: "+1 555 010 3001", matchedUserId: nil),
        DeviceContactDTO(id: "dc5", name: "Dr. Sarah Kim", phoneNumber: "+1 555 010 3002", matchedUserId: nil),
        DeviceContactDTO(id: "dc6", name: "Jordan Lee", phoneNumber: "+1 555 010 3003", matchedUserId: nil),
    ]
}
