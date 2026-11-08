@testable import Talkora
import Foundation
import UserNotifications
import XCTest
@testable import Core
@testable import Calls

@MainActor
final class CallViewModelNotificationTests: XCTestCase {
    private func makeViewModel(direction: CallDirection, scheduler: SpyNotificationScheduler) -> CallViewModel {
        let request = ActiveCallRequest(conversationId: "c1", counterpartId: "bob", counterpartName: "Bob", type: .voice, direction: direction)
        return CallViewModel(request: request, repository: StubCallRepository(), scheduler: scheduler)
    }

    func test_decline_incomingCall_notifiesMissedCall() async {
        let scheduler = SpyNotificationScheduler()
        let viewModel = makeViewModel(direction: .incoming, scheduler: scheduler)

        await viewModel.decline()

        XCTAssertEqual(scheduler.missedCalls.map(\.callerName), ["Bob"])
        XCTAssertEqual(scheduler.missedCalls.map(\.conversationId), ["c1"])
    }

    func test_hangUp_incomingCallThatWasNeverAnswered_notifiesMissedCall() async {
        let scheduler = SpyNotificationScheduler()
        let viewModel = makeViewModel(direction: .incoming, scheduler: scheduler)

        await viewModel.hangUp()

        XCTAssertEqual(scheduler.missedCalls.count, 1)
    }

    func test_hangUp_afterAnswering_doesNotNotifyMissedCall() async {
        let scheduler = SpyNotificationScheduler()
        let viewModel = makeViewModel(direction: .incoming, scheduler: scheduler)
        viewModel.answer()

        await viewModel.hangUp()

        XCTAssertTrue(scheduler.missedCalls.isEmpty)
    }
}
