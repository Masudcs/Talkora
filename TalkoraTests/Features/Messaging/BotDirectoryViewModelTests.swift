@testable import Talkora
import Foundation
import XCTest
@testable import Core
@testable import Messaging

@MainActor
final class BotDirectoryViewModelTests: XCTestCase {
    func test_load_withBots_setsLoaded() async {
        let stub = StubBotRepository()
        stub.allBotsResult = .success([Bot(id: "b1", name: "Reminder", description: "Reminds you", capability: .reminders)])
        let viewModel = BotDirectoryViewModel(botRepository: stub, chatRepository: StubChatRepository())

        await viewModel.load()

        XCTAssertEqual(viewModel.state.value?.map(\.id), ["b1"])
    }

    func test_load_withNoBots_setsEmpty() async {
        let viewModel = BotDirectoryViewModel(botRepository: StubBotRepository(), chatRepository: StubChatRepository())

        await viewModel.load()

        guard case .empty = viewModel.state else { return XCTFail("expected .empty, got \(viewModel.state)") }
    }

    func test_load_failure_setsFailed() async {
        let stub = StubBotRepository()
        stub.allBotsResult = .failure(StubFailure.notConfigured)
        let viewModel = BotDirectoryViewModel(botRepository: stub, chatRepository: StubChatRepository())

        await viewModel.load()

        XCTAssertNotNil(viewModel.state.error)
    }
}
