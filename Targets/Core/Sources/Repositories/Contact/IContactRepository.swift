import Foundation

public protocol IContactRepository: Sendable {
    /// The mock "device address book" — some entries already matched to Talkora users.
    func syncDeviceContacts() async throws -> [DeviceContact]
    func searchUsers(query: String) async throws -> [User]
    /// Improve: throttled server-side from the start — see `MockDataStore.sendContactRequest`.
    func sendContactRequest(to userId: String) async throws -> ContactRequest
    func incomingRequests() async throws -> [ContactRequest]
    func respondToRequest(_ requestId: String, accept: Bool) async throws -> ContactRequest
    func myConnections() async throws -> [User]
    func discoverability() async throws -> DiscoverabilityPrivacy
    func setDiscoverability(_ value: DiscoverabilityPrivacy) async throws -> DiscoverabilityPrivacy
    /// Improve: QR add-friend works standalone — no phone-contact sync required. Unlike a
    /// search-based request, an in-person QR scan connects instantly (mutual consent implied).
    func connectViaQR(userId: String) async throws -> User
    /// Demo affordance (no second real device to send a real request from) — mirrors
    /// Module 4's "simulate incoming call".
    func simulateIncomingRequest() async throws -> ContactRequest?
}
