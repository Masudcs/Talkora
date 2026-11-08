@testable import Talkora
import Foundation
import XCTest
@testable import Core
@testable import Messaging

@MainActor
final class ChatSettingsViewModelTests: XCTestCase {
    private let bob = User(id: "bob", displayName: "Bob", handle: "@bob", avatarURL: nil, status: .online, createdAt: Date())

    private func makeConversation(muted: Bool = false) -> Conversation {
        Conversation(id: "c1", kind: .direct, title: "Bob", participantIds: ["me", "bob"], lastMessagePreview: nil, updatedAt: Date(), isMuted: muted)
    }

    private struct Harness {
        let viewModel: ChatSettingsViewModel
        let chat: StubChatRepository
        let privacy: StubPrivacyRepository
        let changes: Box
    }

    @MainActor
    final class Box {
        var conversations: [Conversation] = []
        var blocked: [Bool] = []
    }

    private func makeHarness(blocked: Bool = false) -> Harness {
        let chat = StubChatRepository()
        let privacy = StubPrivacyRepository()
        let box = Box()
        let viewModel = ChatSettingsViewModel(
            conversation: makeConversation(), otherParticipant: bob, isBlockedParticipant: blocked,
            chatRepository: chat, privacyRepository: privacy,
            onConversationChanged: { box.conversations.append($0) }, onBlockChanged: { box.blocked.append($0) }
        )
        return Harness(viewModel: viewModel, chat: chat, privacy: privacy, changes: box)
    }

    func test_updateMuted_success_updatesConversationAndNotifiesThread() async {
        let h = makeHarness()
        h.chat.setMutedResult = .success(makeConversation(muted: true))

        await h.viewModel.updateMuted(true)

        XCTAssertTrue(h.viewModel.conversation.isMuted)
        XCTAssertEqual(h.changes.conversations.map(\.isMuted), [true])
    }

    func test_updateMuted_failure_setsActionErrorAndKeepsConversation() async {
        let h = makeHarness()
        h.chat.setMutedResult = .failure(StubFailure.notConfigured)

        await h.viewModel.updateMuted(true)

        XCTAssertNotNil(h.viewModel.actionError)
        XCTAssertFalse(h.viewModel.conversation.isMuted)
        XCTAssertTrue(h.changes.conversations.isEmpty)
        h.viewModel.dismissError()
        XCTAssertNil(h.viewModel.actionError)
    }

    func test_toggleBlock_blocksThenUnblocksAndNotifiesThread() async {
        let h = makeHarness()

        await h.viewModel.toggleBlock()
        await h.viewModel.toggleBlock()

        XCTAssertEqual(h.changes.blocked, [true, false])
        XCTAssertFalse(h.viewModel.isBlockedParticipant)
    }

    func test_toggleBlock_failure_leavesStateAndSetsError() async {
        let h = makeHarness()
        h.privacy.blockUserResult = .failure(StubFailure.notConfigured)

        await h.viewModel.toggleBlock()

        XCTAssertFalse(h.viewModel.isBlockedParticipant)
        XCTAssertTrue(h.changes.blocked.isEmpty)
        XCTAssertNotNil(h.viewModel.actionError)
    }

    func test_reportParticipant_blankReason_doesNothing() async {
        let h = makeHarness()
        h.viewModel.isReportSheetPresented = true

        await h.viewModel.reportParticipant(reason: "  ")

        XCTAssertTrue(h.viewModel.isReportSheetPresented)
    }

    func test_reportParticipant_validReason_closesSheet() async {
        let h = makeHarness()
        h.viewModel.isReportSheetPresented = true

        await h.viewModel.reportParticipant(reason: "spam")

        XCTAssertFalse(h.viewModel.isReportSheetPresented)
    }
}

@MainActor
final class ChatWallpaperPickerViewModelTests: XCTestCase {
    private func makeConversation(_ wallpaper: ChatWallpaper) -> Conversation {
        Conversation(id: "c1", kind: .direct, title: "Bob", participantIds: ["me", "bob"], lastMessagePreview: nil, updatedAt: Date(), wallpaper: wallpaper)
    }

    func test_select_success_updatesSelectionAndReportsConversation() async {
        let chat = StubChatRepository()
        let target = ChatWallpaper.allCases.first { $0 != .default } ?? .default
        chat.setWallpaperResult = .success(makeConversation(target))
        var reported: [Conversation] = []
        let viewModel = ChatWallpaperPickerViewModel(conversationId: "c1", selected: .default, chatRepository: chat) { reported.append($0) }

        await viewModel.select(target)

        XCTAssertEqual(viewModel.selected, target)
        XCTAssertEqual(reported.map(\.wallpaper), [target])
    }

    func test_select_failure_keepsSelectionAndSetsError() async {
        let chat = StubChatRepository()
        var reported = 0
        let viewModel = ChatWallpaperPickerViewModel(conversationId: "c1", selected: .default, chatRepository: chat) { _ in reported += 1 }

        await viewModel.select(ChatWallpaper.allCases.first { $0 != .default } ?? .default)

        XCTAssertEqual(viewModel.selected, .default)
        XCTAssertNotNil(viewModel.actionError)
        XCTAssertEqual(reported, 0)
    }
}
