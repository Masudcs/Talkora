#if DEBUG
@testable import Talkora
import XCTest
@testable import Core
@testable import Mock
@testable import ContactsFeature
@testable import Stories

@MainActor
final class PreviewSmokeContactsStoriesTests: XCTestCase {
    func test_previewData_contactsArePopulated() {
        XCTAssertFalse(PreviewData.deviceContacts.isEmpty)
        XCTAssertFalse(PreviewData.incomingRequests.isEmpty)
    }

    func test_deviceContacts_scenarios() {
        XCTAssertNotNil(DeviceContactsViewModel(previewScenario: .loaded).state.value)
        XCTAssertTrue(DeviceContactsViewModel(previewScenario: .loading).state.isLoading)
        if case .empty = DeviceContactsViewModel(previewScenario: .empty).state {} else { XCTFail("expected empty") }
        XCTAssertNotNil(DeviceContactsViewModel(previewScenario: .failed).state.error)
    }

    func test_incomingRequests_scenarios() {
        XCTAssertFalse(IncomingRequestsViewModel(previewScenario: .loaded).requests.isEmpty)
        XCTAssertTrue(IncomingRequestsViewModel(previewScenario: .empty).requests.isEmpty)
    }

    func test_myQRCode_scenarios() {
        let loaded = MyQRCodeViewModel(previewScenario: .loaded)
        XCTAssertNotNil(loaded.state.value)
        XCTAssertNotNil(loaded.qrPayload)
        XCTAssertTrue(MyQRCodeViewModel(previewScenario: .loading).state.isLoading)
        XCTAssertNotNil(MyQRCodeViewModel(previewScenario: .failed).state.error)
    }

    func test_scanQR_scenarios() {
        let loaded = ScanQRViewModel(previewScenario: .loaded)
        XCTAssertFalse(loaded.candidates.isEmpty)
        XCTAssertNil(loaded.connectedUser)
        XCTAssertTrue(ScanQRViewModel(previewScenario: .empty).candidates.isEmpty)
        XCTAssertNotNil(ScanQRViewModel(previewScenario: .failed).connectedUser)
    }

    func test_searchUsers_scenarios() {
        let loaded = SearchUsersViewModel(previewScenario: .loaded)
        XCTAssertFalse(loaded.results.isEmpty)
        XCTAssertFalse(loaded.sentRequestUserIds.isEmpty)
        XCTAssertNil(loaded.requestError)
        XCTAssertTrue(SearchUsersViewModel(previewScenario: .empty).results.isEmpty)
        XCTAssertNotNil(SearchUsersViewModel(previewScenario: .failed).requestError)
    }

    func test_closeFriends_scenarios() {
        let loaded = CloseFriendsViewModel(previewScenario: .loaded)
        XCTAssertFalse(loaded.candidates.isEmpty)
        XCTAssertFalse(loaded.selectedIds.isEmpty)
        XCTAssertTrue(CloseFriendsViewModel(previewScenario: .empty).candidates.isEmpty)
    }

    func test_createStory_scenarios() {
        let empty = CreateStoryViewModel(previewScenario: .empty)
        XCTAssertTrue(empty.overlayText.isEmpty)
        XCTAssertFalse(empty.isPosting)

        let filled = CreateStoryViewModel(previewScenario: .filled)
        XCTAssertFalse(filled.overlayText.isEmpty)
        XCTAssertEqual(filled.privacy, .closeFriends)

        XCTAssertTrue(CreateStoryViewModel(previewScenario: .submitting).isPosting)
        XCTAssertNotNil(CreateStoryViewModel(previewScenario: .failed).postError)
    }
}
#endif
