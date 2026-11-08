@testable import Talkora
import Foundation
import XCTest
@testable import Core
@testable import ContactsFeature
@testable import Messaging

final class PINFormatTests: XCTestCase {
    func test_sanitize_keepsOnlyDigitsAndCapsLength() {
        XCTAssertEqual(PINFormat.sanitize("12a34567"), "1234")
        XCTAssertEqual(PINFormat.sanitize("ab"), "")
        XCTAssertEqual(PINFormat.sanitize("98"), "98")
    }
}

final class AsAppErrorTests: XCTestCase {
    private struct Custom: AppError {
        let userMessage = "custom"
        let isRetryable = false
    }

    func test_asAppError_keepsExistingAppError() {
        let error: Error = Custom()
        XCTAssertEqual(error.asAppError.userMessage, "custom")
        XCTAssertFalse(error.asAppError.isRetryable)
    }

    func test_asAppError_wrapsForeignErrorsInGenericAppError() {
        let error: Error = StubFailure.notConfigured
        XCTAssertTrue(error.asAppError is GenericAppError)
        XCTAssertTrue(error.asAppError.isRetryable)
    }
}

@MainActor
final class MyQRCodeViewModelTests: XCTestCase {
    func test_load_success_exposesUserAndQRPayload() async {
        let users = StubUserRepository()
        users.currentUserResult = .success(User(id: "u1", displayName: "Me", handle: "@me", avatarURL: nil, status: .online, createdAt: Date()))
        let viewModel = MyQRCodeViewModel(userRepository: users)

        await viewModel.load()

        XCTAssertEqual(viewModel.state.value?.id, "u1")
        XCTAssertEqual(viewModel.qrPayload, "talkora://contact/u1")
    }

    func test_load_failure_setsFailedAndNoPayload() async {
        let viewModel = MyQRCodeViewModel(userRepository: StubUserRepository())

        await viewModel.load()

        XCTAssertNotNil(viewModel.state.error)
        XCTAssertNil(viewModel.qrPayload)
    }
}

@MainActor
final class GlobalSearchDirectConversationTests: XCTestCase {
    private let bob = User(id: "bob", displayName: "Bob", handle: "@bob", avatarURL: nil, status: .online, createdAt: Date())

    func test_directConversationId_returnsIdFromRepository() async {
        let chat = StubChatRepository()
        chat.findOrCreateDirectConversationResult = .success(Conversation(id: "c9", kind: .direct, title: "Bob", participantIds: ["me", "bob"], lastMessagePreview: nil, updatedAt: Date()))
        let viewModel = GlobalSearchViewModel(repository: StubSearchRepository(), chatRepository: chat)

        let id = await viewModel.directConversationId(with: bob)

        XCTAssertEqual(id, "c9")
    }

    func test_directConversationId_onFailure_returnsNil() async {
        let viewModel = GlobalSearchViewModel(repository: StubSearchRepository(), chatRepository: StubChatRepository())

        let id = await viewModel.directConversationId(with: bob)

        XCTAssertNil(id)
    }
}
