import Foundation

/// Contacts, requests and discoverability, over `APIClientProtocol` — behaves the same against the mock, stubbed and live backends.
public final class ContactRepository: IContactRepository {
    private let api: APIClientProtocol

    public init(api: APIClientProtocol = APIClientProvider.shared.client) {
        self.api = api
    }

    public func syncDeviceContacts() async throws -> [DeviceContact] {
        let dtos: [DeviceContactDTO] = try await api.request(ContactRoutes.deviceContacts)
        return dtos.map { $0.toDomain() }
    }

    public func searchUsers(query: String) async throws -> [User] {
        let dtos: [UserDTO] = try await api.request(ContactRoutes.searchUsers(query: query))
        return dtos.map { $0.toDomain() }
    }

    public func sendContactRequest(to userId: String) async throws -> ContactRequest {
        do {
            let dto: ContactRequestDTO = try await api.request(
                ContactRoutes.sendRequest(toUserId: userId)
            )
            return dto.toDomain()
        } catch {
            throw ContactError.throttled
        }
    }

    public func incomingRequests() async throws -> [ContactRequest] {
        let dtos: [ContactRequestDTO] = try await api.request(ContactRoutes.incomingRequests)
        return dtos.map { $0.toDomain() }
    }

    public func respondToRequest(_ requestId: String, accept: Bool) async throws -> ContactRequest {
        let dto: ContactRequestDTO = try await api.request(
            ContactRoutes.respond(requestId: requestId, accept: accept)
        )
        return dto.toDomain()
    }

    public func myConnections() async throws -> [User] {
        let dtos: [UserDTO] = try await api.request(ContactRoutes.connections)
        return dtos.map { $0.toDomain() }
    }

    public func discoverability() async throws -> DiscoverabilityPrivacy {
        let value: String = try await api.request(ContactRoutes.discoverability)
        return DiscoverabilityPrivacy(rawValue: value) ?? .everyone
    }

    public func setDiscoverability(_ value: DiscoverabilityPrivacy) async throws -> DiscoverabilityPrivacy {
        let updated: String = try await api.request(
            ContactRoutes.setDiscoverability(value: value.rawValue)
        )
        return DiscoverabilityPrivacy(rawValue: updated) ?? .everyone
    }

    public func connectViaQR(userId: String) async throws -> User {
        let dto: UserDTO = try await api.request(
            ContactRoutes.connectViaQR(userId: userId)
        )
        return dto.toDomain()
    }

    public func simulateIncomingRequest() async throws -> ContactRequest? {
        let dto: ContactRequestDTO? = try? await api.request(ContactRoutes.simulateIncomingRequest)
        return dto?.toDomain()
    }
}
