@testable import Talkora
import Foundation
@testable import Core

final class StubCallRepository: ICallRepository {
    var callHistoryResult: Result<[Call], Error> = .success([])
    var startCallResult: Result<Call, Error> = .failure(StubFailure.notConfigured)
    var endCallResult: Result<Call, Error> = .failure(StubFailure.notConfigured)
    private(set) var endCallCount = 0
    private(set) var lastEndOutcome: CallOutcome?

    func callHistory() async throws -> [Call] {
        try callHistoryResult.get()
    }

    func startCall(conversationId: String, counterpartId: String, type: CallType, direction: CallDirection) async throws -> Call {
        try startCallResult.get()
    }

    func endCall(_ callId: String, outcome: CallOutcome, duration: TimeInterval) async throws -> Call {
        endCallCount += 1
        lastEndOutcome = outcome
        return try endCallResult.get()
    }
}
