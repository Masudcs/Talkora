import Foundation

public protocol ICallRepository: Sendable {
    func callHistory() async throws -> [Call]
    /// Creates a call record that is still ringing; `endCall` then records how it finished.
    func startCall(conversationId: String, counterpartId: String, type: CallType, direction: CallDirection) async throws -> Call
    func endCall(_ callId: String, outcome: CallOutcome, duration: TimeInterval) async throws -> Call
}
