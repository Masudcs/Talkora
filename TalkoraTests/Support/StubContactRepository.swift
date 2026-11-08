@testable import Talkora
import Foundation
@testable import Core

final class StubContactRepository: IContactRepository {
    var syncDeviceContactsResult: Result<[DeviceContact], Error> = .success([])
    var searchUsersResult: Result<[User], Error> = .success([])
    var sendContactRequestResult: Result<ContactRequest, Error> = .failure(StubFailure.notConfigured)
    var incomingRequestsResult: Result<[ContactRequest], Error> = .success([])
    var respondToRequestResult: Result<ContactRequest, Error> = .failure(StubFailure.notConfigured)
    var myConnectionsResult: Result<[User], Error> = .success([])
    var discoverabilityResult: Result<DiscoverabilityPrivacy, Error> = .success(.everyone)
    var setDiscoverabilityResult: Result<DiscoverabilityPrivacy, Error> = .failure(StubFailure.notConfigured)
    var connectViaQRResult: Result<User, Error> = .failure(StubFailure.notConfigured)
    var simulateIncomingRequestResult: Result<ContactRequest?, Error> = .success(nil)
    private(set) var lastSearchQuery: String?
    private(set) var lastRespondAccept: Bool?

    func syncDeviceContacts() async throws -> [DeviceContact] {
        try syncDeviceContactsResult.get()
    }

    func searchUsers(query: String) async throws -> [User] {
        lastSearchQuery = query
        return try searchUsersResult.get()
    }

    func sendContactRequest(to userId: String) async throws -> ContactRequest {
        try sendContactRequestResult.get()
    }

    func incomingRequests() async throws -> [ContactRequest] {
        try incomingRequestsResult.get()
    }

    func respondToRequest(_ requestId: String, accept: Bool) async throws -> ContactRequest {
        lastRespondAccept = accept
        return try respondToRequestResult.get()
    }

    func myConnections() async throws -> [User] {
        try myConnectionsResult.get()
    }

    func discoverability() async throws -> DiscoverabilityPrivacy {
        try discoverabilityResult.get()
    }

    func setDiscoverability(_ value: DiscoverabilityPrivacy) async throws -> DiscoverabilityPrivacy {
        try setDiscoverabilityResult.get()
    }

    func connectViaQR(userId: String) async throws -> User {
        try connectViaQRResult.get()
    }

    func simulateIncomingRequest() async throws -> ContactRequest? {
        try simulateIncomingRequestResult.get()
    }
}
