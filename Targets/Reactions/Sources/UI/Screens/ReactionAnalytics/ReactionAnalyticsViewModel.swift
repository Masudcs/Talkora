import Foundation
import Observation
import Core
import Mock

/// Lightweight (Discord-style) reaction analytics for group admins — aggregated
/// client-side from the same `Message.reactions` every bubble already renders, not a
/// separate analytics pipeline.
@MainActor
@Observable
final class ReactionAnalyticsViewModel {
    let conversationId: String
    private(set) var state: LoadableState<ReactionSummary> = .idle

    @ObservationIgnored private var isPreview = false
    private let chatRepository: IMessageRepository

    init(conversationId: String, chatRepository: IMessageRepository = ChatRepository()) {
        self.conversationId = conversationId
        self.chatRepository = chatRepository
    }

    /// Aggregates over the first page of messages only (`cursor: nil`), so older reactions in long conversations are not counted.
    /// Counts are reactors per emoji, summed across messages.
    func load() async {
        guard !isPreview else { return }
        state = .loading
        let page: Page<Message>
        do {
            page = try await chatRepository.messages(conversationId: conversationId, cursor: nil)
        } catch {
            state = .failed(error.asAppError)
            return
        }
        var totals: [String: Int] = [:]
        for message in page.items {
            for reaction in message.reactions {
                totals[reaction.emoji, default: 0] += reaction.userIds.count
            }
        }
        let emojiTotals = totals.map { EmojiTotal(emoji: $0.key, count: $0.value) }.sorted { $0.count > $1.count }
        // Top 5 by total reactor count; ties keep no guaranteed order.
        let topMessages = page.items
            .filter { !$0.reactions.isEmpty }
            .sorted { $0.reactions.reduce(0) { $0 + $1.userIds.count } > $1.reactions.reduce(0) { $0 + $1.userIds.count } }
            .prefix(5)
            .map { $0 }
        state = emojiTotals.isEmpty ? .empty : .loaded(ReactionSummary(emojiTotals: emojiTotals, topMessages: topMessages))
    }

    /// Total reactors across all emoji on a message (the same measure used for ranking).
    func totalReactionCount(for message: Message) -> Int {
        message.reactions.reduce(0) { $0 + $1.userIds.count }
    }
}

#if DEBUG
extension ReactionAnalyticsViewModel {
    convenience init(previewScenario scenario: PreviewScenario) {
        self.init(conversationId: PreviewData.groupConversation.id)
        isPreview = true
        switch scenario {
        case .loaded: state = .loaded(PreviewData.reactionSummary)
        case .loading: state = .loading
        case .empty: state = .empty
        case .failed: state = .failed(PreviewData.error)
        }
    }
}
#endif
