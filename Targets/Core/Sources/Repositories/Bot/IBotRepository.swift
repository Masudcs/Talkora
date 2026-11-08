import Foundation

public protocol IBotRepository: Sendable {
    func allBots() async throws -> [Bot]
}
