import Foundation
import Observation
import Core
import Mock

/// Loads call history and resolves each call's counterpart name, plus the direct conversations used to simulate an incoming call.
@MainActor
@Observable
final class CallLogViewModel {
    @ObservationIgnored private var isPreview = false
    private(set) var state: LoadableState<[Call]> = .idle
    /// Counterpart user id -> display name; `Call` only stores the id. Missing names render as "Unknown".
    private(set) var counterpartNames: [String: String] = [:]
    private var directConversations: [Conversation] = []
    private var currentUserId: String = ""

    private let callRepository: ICallRepository
    private let chatRepository: IConversationRepository
    private let userRepository: IUserRepository

    init(callRepository: ICallRepository = CallRepository(), chatRepository: IConversationRepository = ChatRepository(), userRepository: IUserRepository = UserRepository()) {
        self.callRepository = callRepository
        self.chatRepository = chatRepository
        self.userRepository = userRepository
    }

    /// Loads current user, history and direct conversations, then looks up each unseen counterpart's name
    /// (a failed lookup is skipped, not fatal). Any other failure puts the screen in `.failed`.
    func load() async {
        guard !isPreview else { return }
        state = .loading
        do {
            currentUserId = try await userRepository.currentUser().id
            let calls = try await callRepository.callHistory()
            directConversations = try await chatRepository.conversations().filter { $0.kind == .direct }
            for call in calls where counterpartNames[call.counterpartId] == nil {
                if let user = try? await userRepository.user(id: call.counterpartId) {
                    counterpartNames[call.counterpartId] = user.displayName
                }
            }
            state = calls.isEmpty ? .empty : .loaded(calls)
        } catch {
            state = .failed(error.asAppError)
        }
    }

    func name(for call: Call) -> String {
        counterpartNames[call.counterpartId] ?? "Unknown"
    }

    /// Outgoing request for the same conversation, person and call type as a past call.
    func redialRequest(for call: Call) -> ActiveCallRequest {
        ActiveCallRequest(conversationId: call.conversationId, counterpartId: call.counterpartId, counterpartName: name(for: call), type: call.type, direction: .outgoing)
    }

    /// Backs the "Simulate Incoming Call" affordance — picks a random existing 1:1
    /// contact so the demo can showcase the incoming-call UI without a real second device.
    func randomIncomingCallRequest() -> ActiveCallRequest? {
        guard let conversation = directConversations.randomElement(),
              let counterpartId = conversation.participantIds.first(where: { $0 != currentUserId }) else {
            return nil
        }
        let name = counterpartNames[counterpartId] ?? conversation.title
        return ActiveCallRequest(conversationId: conversation.id, counterpartId: counterpartId, counterpartName: name, type: Bool.random() ? .voice : .video, direction: .incoming)
    }
}

#if DEBUG
extension CallLogViewModel {
    convenience init(previewScenario scenario: PreviewScenario) {
        self.init()
        isPreview = true
        state = scenario.state(PreviewData.calls)
        counterpartNames = PreviewData.userNames
    }
}
#endif
