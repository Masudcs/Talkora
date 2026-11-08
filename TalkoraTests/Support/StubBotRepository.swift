@testable import Talkora
import Foundation
@testable import Core

final class StubBotRepository: IBotRepository {
    var allBotsResult: Result<[Bot], Error> = .success([])

    func allBots() async throws -> [Bot] {
        try allBotsResult.get()
    }
}
