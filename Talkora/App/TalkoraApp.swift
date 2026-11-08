import SwiftUI
import Core

/// App entry point. The only wiring at launch is the notification quick-reply handler, which sends the typed text through a `ChatRepository`; a failed send is silently dropped.
@main
struct TalkoraApp: App {
    init() {
        let messageRepository: IMessageRepository = ChatRepository()
        NotificationScheduler.shared.onQuickReply = { text, conversationId in
            _ = try? await messageRepository.sendMessage(text: text, conversationId: conversationId, replyToMessageId: nil)
        }
    }

    var body: some Scene {
        WindowGroup {
            AppShellView()
        }
    }
}
