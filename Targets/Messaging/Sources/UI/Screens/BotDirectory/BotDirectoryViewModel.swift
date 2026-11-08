import Foundation
import Observation
import Core

@MainActor
@Observable
final class BotDirectoryViewModel {
    private(set) var state: LoadableState<[Bot]> = .idle

    @ObservationIgnored private var isPreview = false
    private let botRepository: IBotRepository
    private let chatRepository: IConversationRepository

    init(botRepository: IBotRepository = BotRepository(), chatRepository: IConversationRepository = ChatRepository()) {
        self.botRepository = botRepository
        self.chatRepository = chatRepository
    }

    func load() async {
        guard !isPreview else { return }
        state = .loading
        do {
            let bots = try await botRepository.allBots()
            state = bots.isEmpty ? .empty : .loaded(bots)
        } catch {
            state = .failed(error.asAppError)
        }
    }

    func startChat(with bot: Bot) async -> Conversation? {
        try? await chatRepository.findOrCreateDirectConversation(with: bot.id)
    }
}

#if DEBUG
extension BotDirectoryViewModel {
    convenience init(previewScenario scenario: PreviewScenario) {
        self.init()
        isPreview = true
        state = scenario.state(Self.previewBots)
    }

    /// Bots listed in the directory previews, mirroring the seeded mock bots.
    static let previewBots: [Bot] = [
        Bot(id: "bot1", name: "Reminder Bot", description: "Tell it what to remember and it'll schedule a real reminder notification.", capability: .reminders),
        Bot(id: "bot2", name: "Fact Bot", description: "Send it anything and get a random fun fact back.", capability: .funFacts),
    ]
}
#endif
