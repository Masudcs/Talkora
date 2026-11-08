import Foundation

/// Call history and call records, over `APIClientProtocol` — behaves the same against the mock, stubbed and live backends.
public final class CallRepository: ICallRepository {
    private let api: APIClientProtocol

    public init(api: APIClientProtocol = APIClientProvider.shared.client) {
        self.api = api
    }

    public func callHistory() async throws -> [Call] {
        let dtos: [CallDTO] = try await api.request(CallRoutes.history)
        return dtos.map { $0.toDomain() }
    }

    public func startCall(conversationId: String, counterpartId: String, type: CallType, direction: CallDirection) async throws -> Call {
        let dto: CallDTO = try await api.request(
            CallRoutes.start(conversationId: conversationId, counterpartId: counterpartId, type: type.rawValue, direction: direction.rawValue)
        )
        return dto.toDomain()
    }

    public func endCall(_ callId: String, outcome: CallOutcome, duration: TimeInterval) async throws -> Call {
        let dto: CallDTO = try await api.request(
            CallRoutes.end(callId: callId, outcome: outcome.rawValue, duration: duration)
        )
        return dto.toDomain()
    }
}
