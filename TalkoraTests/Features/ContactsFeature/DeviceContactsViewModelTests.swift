@testable import Talkora
import Foundation
import XCTest
@testable import Core
@testable import ContactsFeature

private func makeRequest(_ id: String, from: String) -> ContactRequest {
    ContactRequest(id: id, fromUserId: from, toUserId: "me", status: .pending, createdAt: Date())
}

@MainActor
final class DeviceContactsViewModelTests: XCTestCase {
    private func makeContact(_ id: String, matched: String?) -> DeviceContact {
        DeviceContact(id: id, name: id, phoneNumber: "+1555", matchedUserId: matched)
    }

    func test_sync_success_setsLoaded() async {
        let contacts = StubContactRepository()
        contacts.syncDeviceContactsResult = .success([makeContact("d1", matched: nil)])
        let viewModel = DeviceContactsViewModel(contactRepository: contacts)

        await viewModel.sync()

        XCTAssertEqual(viewModel.state.value?.map(\.id), ["d1"])
    }

    func test_sync_empty_setsEmpty() async {
        let viewModel = DeviceContactsViewModel(contactRepository: StubContactRepository())

        await viewModel.sync()

        guard case .empty = viewModel.state else { return XCTFail("expected .empty, got \(viewModel.state)") }
    }

    func test_sync_failure_setsFailed() async {
        let contacts = StubContactRepository()
        contacts.syncDeviceContactsResult = .failure(StubFailure.notConfigured)
        let viewModel = DeviceContactsViewModel(contactRepository: contacts)

        await viewModel.sync()

        XCTAssertNotNil(viewModel.state.error)
    }

    func test_connect_matchedContact_marksConnected() async {
        let contacts = StubContactRepository()
        contacts.sendContactRequestResult = .success(makeRequest("r1", from: "me"))
        let viewModel = DeviceContactsViewModel(contactRepository: contacts)

        await viewModel.connect(makeContact("d1", matched: "u1"))

        XCTAssertEqual(viewModel.connectedIds, ["u1"])
    }

    func test_connect_unmatchedContact_isIgnored() async {
        let viewModel = DeviceContactsViewModel(contactRepository: StubContactRepository())

        await viewModel.connect(makeContact("d1", matched: nil))

        XCTAssertTrue(viewModel.connectedIds.isEmpty)
    }
}
