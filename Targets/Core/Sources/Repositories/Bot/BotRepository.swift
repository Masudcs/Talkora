import Foundation

/// The bot directory, over `APIClientProtocol` — behaves the same against the mock, stubbed and live backends.
public final class BotRepository: IBotRepository {
    private let api: APIClientProtocol

    public init(api: APIClientProtocol = APIClientProvider.shared.client) {
        self.api = api
    }

    public func allBots() async throws -> [Bot] {
        let dtos: [BotDTO] = try await api.request(BotRoutes.allBots)
        return dtos.map { $0.toDomain() }
    }
}
