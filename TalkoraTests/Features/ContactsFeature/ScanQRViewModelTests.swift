@testable import Talkora
import Foundation
import XCTest
@testable import Core
@testable import ContactsFeature

private func makeUser(_ id: String, _ name: String = "User") -> User {
    User(id: id, displayName: name, handle: "@\(id)", avatarURL: nil, status: .online, createdAt: Date())
}

@MainActor
final class ScanQRViewModelTests: XCTestCase {
    func test_load_excludesCurrentUserFromCandidates() async {
        let users = StubUserRepository()
        users.currentUserResult = .success(makeUser("me"))
        users.allUsersResult = .success([makeUser("me"), makeUser("bob"), makeUser("amy")])
        let viewModel = ScanQRViewModel(contactRepository: StubContactRepository(), userRepository: users)

        await viewModel.load()

        XCTAssertEqual(viewModel.candidates.map(\.id), ["bob", "amy"])
    }

    func test_load_failure_leavesCandidatesEmpty() async {
        let viewModel = ScanQRViewModel(contactRepository: StubContactRepository(), userRepository: StubUserRepository())

        await viewModel.load()

        XCTAssertTrue(viewModel.candidates.isEmpty)
    }

    func test_simulateScan_success_setsConnectedUser() async {
        let contacts = StubContactRepository()
        contacts.connectViaQRResult = .success(makeUser("bob"))
        let viewModel = ScanQRViewModel(contactRepository: contacts, userRepository: StubUserRepository())

        await viewModel.simulateScan(makeUser("bob"))

        XCTAssertEqual(viewModel.connectedUser?.id, "bob")
        XCTAssertNil(viewModel.errorMessage)
    }

    func test_simulateScan_failure_setsError() async {
        let viewModel = ScanQRViewModel(contactRepository: StubContactRepository(), userRepository: StubUserRepository())

        await viewModel.simulateScan(makeUser("bob"))

        XCTAssertNil(viewModel.connectedUser)
        XCTAssertNotNil(viewModel.errorMessage)
    }
}
