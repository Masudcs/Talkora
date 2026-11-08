import Foundation

/// Users and the current profile, over `APIClientProtocol` — behaves the same against the mock, stubbed and live backends.
public final class UserRepository: IUserRepository {
    private let api: APIClientProtocol

    public init(api: APIClientProtocol = APIClientProvider.shared.client) {
        self.api = api
    }

    public func currentUser() async throws -> User {
        let dto: UserDTO = try await api.request(UserRoutes.me)
        return dto.toDomain()
    }

    public func user(id: String) async throws -> User {
        let dto: UserDTO = try await api.request(UserRoutes.user(id: id))
        return dto.toDomain()
    }

    public func allUsers() async throws -> [User] {
        let dtos: [UserDTO] = try await api.request(UserRoutes.allUsers)
        return dtos.map { $0.toDomain() }
    }

    public func updateProfile(displayName: String, bio: String, avatarURL: URL?) async throws -> User {
        let me = try await currentUser()
        let dto: UserDTO = try await api.request(
            UserRoutes.updateProfile(userId: me.id, displayName: displayName, bio: bio, avatarURL: avatarURL?.absoluteString)
        )
        return dto.toDomain()
    }
}
