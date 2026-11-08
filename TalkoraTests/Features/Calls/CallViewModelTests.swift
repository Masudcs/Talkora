@testable import Talkora
import Foundation
import XCTest
@testable import Core
@testable import Calls

private func makeCall(_ id: String, counterpart: String = "bob") -> Call {
    Call(id: id, conversationId: "c1", counterpartId: counterpart, type: .voice, direction: .outgoing,
         outcome: .completed, startedAt: Date(), duration: 10)
}

@MainActor
final class CallViewModelTests: XCTestCase {
    // Incoming requests are used so no random ring timer is started, and answered
    // calls are always hung up so the background timers are cancelled.
    private func makeViewModel(calls: StubCallRepository, direction: CallDirection = .incoming, type: CallType = .voice) -> CallViewModel {
        let request = ActiveCallRequest(conversationId: "c1", counterpartId: "bob", counterpartName: "Bob", type: type, direction: direction)
        return CallViewModel(request: request, repository: calls)
    }

    private func makeStubWithCall() -> StubCallRepository {
        let calls = StubCallRepository()
        calls.startCallResult = .success(makeCall("k1"))
        calls.endCallResult = .success(makeCall("k1"))
        return calls
    }

    func test_init_startsRinging() {
        let viewModel = makeViewModel(calls: StubCallRepository())

        guard case .ringing = viewModel.status else { return XCTFail("expected .ringing") }
        XCTAssertEqual(viewModel.elapsed, 0)
        XCTAssertTrue(viewModel.isCameraOn)
        XCTAssertFalse(viewModel.isMuted)
    }

    func test_answer_whileRinging_connects() async {
        let viewModel = makeViewModel(calls: makeStubWithCall())
        await viewModel.start()

        viewModel.answer()

        guard case .connected = viewModel.status else { return XCTFail("expected .connected") }
        await viewModel.hangUp()
    }

    func test_hangUp_afterConnect_endsWithCompleted() async {
        let calls = makeStubWithCall()
        let viewModel = makeViewModel(calls: calls)
        await viewModel.start()
        viewModel.answer()

        await viewModel.hangUp()

        guard case .ended = viewModel.status else { return XCTFail("expected .ended") }
        XCTAssertEqual(calls.lastEndOutcome, .completed)
        XCTAssertEqual(calls.endCallCount, 1)
    }

    func test_answer_afterEnded_doesNotReconnect() async {
        let viewModel = makeViewModel(calls: makeStubWithCall())
        await viewModel.start()
        viewModel.answer()
        await viewModel.hangUp()

        viewModel.answer()

        guard case .ended = viewModel.status else { return XCTFail("expected .ended") }
    }

    func test_hangUp_outgoingWhileRinging_endsWithNoAnswer() async {
        let calls = makeStubWithCall()
        let viewModel = makeViewModel(calls: calls, direction: .outgoing)
        await viewModel.start()

        await viewModel.hangUp()

        guard case .ended = viewModel.status else { return XCTFail("expected .ended") }
        XCTAssertEqual(calls.lastEndOutcome, .noAnswer)
    }

    func test_hangUp_withoutStartedRecord_doesNotCallEndCall() async {
        let calls = StubCallRepository()
        let viewModel = makeViewModel(calls: calls, direction: .outgoing)

        await viewModel.hangUp()

        guard case .ended = viewModel.status else { return XCTFail("expected .ended") }
        XCTAssertEqual(calls.endCallCount, 0)
    }
}
