import Foundation
import Observation
import Core
import Mock

@MainActor
@Observable
final class ConversationListViewModel {
    @ObservationIgnored private var isPreview = false
    private(set) var state: LoadableState<[Conversation]> = .idle
    private let repository: IConversationRepository

    init(repository: IConversationRepository = ChatRepository()) {
        self.repository = repository
    }

    func load() async {
        guard !isPreview else { return }
        state = .loading
        do {
            let items = try await repository.conversations()
            state = items.isEmpty ? .empty : .loaded(items)
        } catch {
            state = .failed(error.asAppError)
        }
    }
}

#if DEBUG
extension ConversationListViewModel {
    convenience init(previewScenario scenario: PreviewScenario) {
        self.init()
        isPreview = true
        state = scenario.state(PreviewData.conversations)
    }
}
#endif
