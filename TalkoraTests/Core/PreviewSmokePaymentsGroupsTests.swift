#if DEBUG
@testable import Talkora
import XCTest
@testable import Core
@testable import Messaging
@testable import Calls
@testable import Payments

@MainActor
final class PreviewSmokePaymentsGroupsTests: XCTestCase {
    func test_botDirectory_scenarios() {
        guard case .loaded(let bots) = BotDirectoryViewModel(previewScenario: .loaded).state else { return XCTFail("expected loaded") }
        XCTAssertFalse(bots.isEmpty)
        XCTAssertTrue(BotDirectoryViewModel(previewScenario: .loading).state.isLoading)
        guard case .empty = BotDirectoryViewModel(previewScenario: .empty).state else { return XCTFail("expected empty") }
        XCTAssertNotNil(BotDirectoryViewModel(previewScenario: .failed).state.error)
    }

    func test_botDirectory_loadKeepsPreviewState() async {
        let viewModel = BotDirectoryViewModel(previewScenario: .empty)
        await viewModel.load()
        guard case .empty = viewModel.state else { return XCTFail("load() should not change preview state") }
    }

    func test_kyc_scenarios() {
        XCTAssertFalse(KYCViewModel(previewScenario: .empty).canSubmit)
        XCTAssertTrue(KYCViewModel(previewScenario: .filled).canSubmit)
        XCTAssertFalse(KYCViewModel(previewScenario: .invalid).canSubmit)
        XCTAssertTrue(KYCViewModel(previewScenario: .submitting).isSubmitting)
    }

    func test_topUp_scenarios() {
        XCTAssertFalse(TopUpViewModel(previewScenario: .empty).canSubmit)
        XCTAssertTrue(TopUpViewModel(previewScenario: .filled).canSubmit)
        XCTAssertFalse(TopUpViewModel(previewScenario: .invalid).canSubmit)
        XCTAssertTrue(TopUpViewModel(previewScenario: .submitting).isSubmitting)
    }

    func test_paymentCompose_scenarios() {
        for mode in [PaymentComposeMode.send, .request] {
            XCTAssertEqual(PaymentComposeViewModel(previewMode: mode, scenario: .empty).mode, mode)
            XCTAssertFalse(PaymentComposeViewModel(previewMode: mode, scenario: .empty).canSubmit)
            XCTAssertTrue(PaymentComposeViewModel(previewMode: mode, scenario: .filled).canSubmit)
            XCTAssertFalse(PaymentComposeViewModel(previewMode: mode, scenario: .invalid).canSubmit)
            XCTAssertTrue(PaymentComposeViewModel(previewMode: mode, scenario: .submitting).isSubmitting)
            XCTAssertNotNil(PaymentComposeViewModel(previewMode: mode, scenario: .failed).error)
        }
    }

    func test_createChannelAndCommunity_scenarios() {
        XCTAssertFalse(CreateChannelViewModel(previewScenario: .empty).canSubmit)
        XCTAssertTrue(CreateChannelViewModel(previewScenario: .filled).canSubmit)
        XCTAssertFalse(CreateChannelViewModel(previewScenario: .invalid).canSubmit)
        XCTAssertTrue(CreateChannelViewModel(previewScenario: .submitting).isSubmitting)
        XCTAssertFalse(CreateCommunityViewModel(previewScenario: .empty).canSubmit)
        XCTAssertTrue(CreateCommunityViewModel(previewScenario: .filled).canSubmit)
        XCTAssertFalse(CreateCommunityViewModel(previewScenario: .invalid).canSubmit)
        XCTAssertTrue(CreateCommunityViewModel(previewScenario: .submitting).isSubmitting)
    }

    func test_createGroup_scenarios() async {
        XCTAssertFalse(CreateGroupViewModel(previewScenario: .empty).candidates.isEmpty)
        XCTAssertFalse(CreateGroupViewModel(previewScenario: .empty).canCreate)
        XCTAssertFalse(CreateGroupViewModel(previewScenario: .invalid).canCreate)
        XCTAssertTrue(CreateGroupViewModel(previewScenario: .filled).canCreate)
        XCTAssertTrue(CreateGroupViewModel(previewScenario: .submitting).state.isLoading)
        XCTAssertNotNil(CreateGroupViewModel(previewScenario: .failed).state.error)
        let viewModel = CreateGroupViewModel(previewScenario: .filled)
        let count = viewModel.candidates.count
        await viewModel.loadCandidates()
        XCTAssertEqual(viewModel.candidates.count, count)
    }

    func test_addMembers_scenarios() async {
        let empty = AddMembersViewModel(previewScenario: .empty)
        XCTAssertFalse(empty.candidates.isEmpty)
        XCTAssertFalse(empty.canAdd)
        XCTAssertTrue(AddMembersViewModel(previewScenario: .invalid).candidates.isEmpty)
        XCTAssertTrue(AddMembersViewModel(previewScenario: .filled).canAdd)
        XCTAssertTrue(AddMembersViewModel(previewScenario: .submitting).state.isLoading)
        XCTAssertNotNil(AddMembersViewModel(previewScenario: .failed).state.error)
        let viewModel = AddMembersViewModel(previewScenario: .filled)
        let count = viewModel.candidates.count
        await viewModel.loadCandidates()
        XCTAssertEqual(viewModel.candidates.count, count)
    }

    func test_call_scenarios() async {
        let incoming = CallViewModel(previewScenario: .incomingRinging)
        XCTAssertEqual(incoming.status, .ringing)
        XCTAssertEqual(incoming.request.direction, .incoming)
        XCTAssertEqual(CallViewModel(previewScenario: .outgoingRinging).request.direction, .outgoing)
        XCTAssertEqual(CallViewModel(previewScenario: .connectedVoice).status, .connected)
        let video = CallViewModel(previewScenario: .connectedVideo)
        XCTAssertEqual(video.status, .connected)
        XCTAssertEqual(video.request.type, .video)
        let degraded = CallViewModel(previewScenario: .degradedVideo)
        XCTAssertTrue(degraded.isDegradedToAudioOnly)
        XCTAssertEqual(degraded.networkQuality, .poor)
        XCTAssertEqual(CallViewModel(previewScenario: .ended).status, .ended)

        let outgoing = CallViewModel(previewScenario: .outgoingRinging)
        await outgoing.start()
        XCTAssertEqual(outgoing.status, .ringing)
    }
}
#endif
