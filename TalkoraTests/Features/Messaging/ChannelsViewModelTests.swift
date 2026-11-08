@testable import Talkora
import Foundation
import XCTest
@testable import Core
@testable import Messaging

@MainActor
final class CreateChannelViewModelTests: XCTestCase {
    func test_canSubmit_isFalse_whenTitleBlank() {
        let viewModel = CreateChannelViewModel { _, _ in }
        viewModel.title = "   "
        XCTAssertFalse(viewModel.canSubmit)
    }

    func test_submit_passesTitleAndNilDescription_whenDescriptionEmpty() async {
        var received: (String, String?)?
        let viewModel = CreateChannelViewModel { received = ($0, $1) }
        viewModel.title = "News"

        await viewModel.submit()

        XCTAssertEqual(received?.0, "News")
        XCTAssertNil(received?.1)
        XCTAssertFalse(viewModel.isSubmitting)
    }

    func test_submit_doesNothing_whenTitleBlank() async {
        var called = false
        let viewModel = CreateChannelViewModel { _, _ in called = true }

        await viewModel.submit()

        XCTAssertFalse(called)
    }
}

@MainActor
final class CreateCommunityViewModelTests: XCTestCase {
    func test_submit_passesDescription_whenProvided() async {
        var received: (String, String?)?
        let viewModel = CreateCommunityViewModel { received = ($0, $1) }
        viewModel.title = "Neighbors"
        viewModel.description = "Local group"

        await viewModel.submit()

        XCTAssertEqual(received?.0, "Neighbors")
        XCTAssertEqual(received?.1, "Local group")
    }

    func test_canSubmit_isFalse_whenTitleBlank() {
        let viewModel = CreateCommunityViewModel { _, _ in }
        XCTAssertFalse(viewModel.canSubmit)
    }
}
