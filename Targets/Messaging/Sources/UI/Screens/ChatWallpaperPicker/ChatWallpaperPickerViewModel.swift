import Foundation
import Observation
import Core

@MainActor
@Observable
final class ChatWallpaperPickerViewModel {
    let conversationId: String
    private(set) var selected: ChatWallpaper
    private(set) var actionError: AppError?

    private let chatRepository: IConversationRepository
    private let onChanged: (Conversation) -> Void

    init(conversationId: String, selected: ChatWallpaper, chatRepository: IConversationRepository = ChatRepository(), onChanged: @escaping (Conversation) -> Void) {
        self.conversationId = conversationId
        self.selected = selected
        self.chatRepository = chatRepository
        self.onChanged = onChanged
    }

    func select(_ wallpaper: ChatWallpaper) async {
        do {
            let updated = try await chatRepository.setWallpaper(wallpaper, for: conversationId)
            selected = updated.wallpaper
            onChanged(updated)
        } catch {
            actionError = error.asAppError
        }
    }
}
