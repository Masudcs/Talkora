import Foundation

/// Wire-format address-book entry; `matchedUserId` is set when the number belongs to a Talkora user.
public struct DeviceContactDTO: Codable, Sendable, Hashable {
    public let id: String
    public let name: String
    public let phoneNumber: String
    public let matchedUserId: String?

    public init(id: String, name: String, phoneNumber: String, matchedUserId: String?) {
        self.id = id
        self.name = name
        self.phoneNumber = phoneNumber
        self.matchedUserId = matchedUserId
    }
}
