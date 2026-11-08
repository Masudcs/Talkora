import Foundation

public enum ContactRequestStatus: String, Sendable {
    case pending
    case accepted
    case declined
}

/// A request from `fromUserId` asking `toUserId` to connect.
public struct ContactRequest: Identifiable, Hashable, Sendable {
    public let id: String
    public let fromUserId: String
    public let toUserId: String
    public let status: ContactRequestStatus
    public let createdAt: Date

    public init(id: String, fromUserId: String, toUserId: String, status: ContactRequestStatus, createdAt: Date) {
        self.id = id
        self.fromUserId = fromUserId
        self.toUserId = toUserId
        self.status = status
        self.createdAt = createdAt
    }
}

/// An address-book entry; `matchedUserId` is non-nil when it matches an existing Talkora user.
public struct DeviceContact: Identifiable, Hashable, Sendable {
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

/// Improve: shown prominently on the Contacts screen itself, not buried in Settings.
public enum DiscoverabilityPrivacy: String, Sendable, CaseIterable {
    case everyone
    case contactsOnly
    case nobody
}
