@testable import Talkora
import XCTest
@testable import Core
@testable import Mock

final class ChatRepositoryTests: XCTestCase {
    /// Deterministic environment for tests: zero simulated latency/error-injection so
    /// results don't depend on which scheme happens to be running the test bundle.
    private let testEnvironment = AppEnvironment(
        name: .development,
        apiBaseURL: URL(string: "https://test.local")!,
        isLoggingEnabled: false,
        displayName: "Test"
    )

    func test_conversations_mapsDTOsToDomainModels() async throws {
        let store = MockDataStore()
        let api = MockAPIClient(store: store, environment: testEnvironment)
        let repository = ChatRepository(api: api)

        let conversations = try await repository.conversations()

        XCTAssertFalse(conversations.isEmpty)
        XCTAssertTrue(conversations.contains { $0.id == "c1" })
    }

    func test_messages_paginatesThroughFullHistory() async throws {
        let store = MockDataStore()
        let api = MockAPIClient(store: store, environment: testEnvironment)
        let repository = ChatRepository(api: api)

        let firstPage = try await repository.messages(conversationId: "c1", cursor: nil)
        XCTAssertFalse(firstPage.items.isEmpty)

        if firstPage.hasMore {
            let secondPage = try await repository.messages(conversationId: "c1", cursor: firstPage.nextCursor)
            XCTAssertFalse(secondPage.items.isEmpty)
        }
    }

    func test_sendMessage_appendsToHistoryAndUpdatesPreview() async throws {
        let store = MockDataStore()
        let api = MockAPIClient(store: store, environment: testEnvironment)
        let repository = ChatRepository(api: api)

        let sent = try await repository.sendMessage(text: "Hello there", conversationId: "c1", replyToMessageId: nil)
        XCTAssertEqual(sent.text, "Hello there")
        XCTAssertEqual(sent.deliveryState, .sent)

        let conversation = try await repository.conversation(id: "c1")
        XCTAssertEqual(conversation.lastMessagePreview, "Hello there")
    }

    func test_editMessage_withinWindow_updatesTextAndSetsEditedAt() async throws {
        let store = MockDataStore()
        let api = MockAPIClient(store: store, environment: testEnvironment)
        let repository = ChatRepository(api: api)
        let sent = try await repository.sendMessage(text: "Oops", conversationId: "c1", replyToMessageId: nil)

        let edited = try await repository.editMessage(messageId: sent.id, conversationId: "c1", newText: "Fixed")

        XCTAssertEqual(edited.text, "Fixed")
        XCTAssertNotNil(edited.editedAt)
    }

    func test_editMessage_outsideWindow_throws() async throws {
        let store = MockDataStore()
        let api = MockAPIClient(store: store, environment: testEnvironment)
        let repository = ChatRepository(api: api)
        // Seed message m1 is from 2024 — long past the 15-minute edit window.
        do {
            _ = try await repository.editMessage(messageId: "m1", conversationId: "c1", newText: "Too late")
            XCTFail("Expected an error for editing an expired message")
        } catch {
            // expected
        }
    }

    func test_deleteMessage_marksDeletedAndClearsText() async throws {
        let store = MockDataStore()
        let api = MockAPIClient(store: store, environment: testEnvironment)
        let repository = ChatRepository(api: api)
        let sent = try await repository.sendMessage(text: "Delete me", conversationId: "c1", replyToMessageId: nil)

        try await repository.deleteMessage(messageId: sent.id, conversationId: "c1")

        let page = try await repository.messages(conversationId: "c1", cursor: nil)
        let deleted = page.items.first { $0.id == sent.id }
        XCTAssertEqual(deleted?.isDeleted, true)
        XCTAssertEqual(deleted?.text, "")
    }

    func test_updateSettings_persistsReadReceiptsAndDisappearingDuration() async throws {
        let store = MockDataStore()
        let api = MockAPIClient(store: store, environment: testEnvironment)
        let repository = ChatRepository(api: api)

        let updated = try await repository.updateSettings(conversationId: "c1", readReceiptsEnabled: false, disappearingDuration: 3600)

        XCTAssertFalse(updated.readReceiptsEnabled)
        XCTAssertEqual(updated.disappearingMessagesDuration, 3600)
    }

    func test_simulateDeliveryTicks_progressesToReadWhenReceiptsEnabled() async throws {
        let store = MockDataStore()
        let api = MockAPIClient(store: store, environment: testEnvironment)
        let repository = ChatRepository(api: api)
        let sent = try await repository.sendMessage(text: "Ping", conversationId: "c1", replyToMessageId: nil)

        let ticked = try await repository.simulateDeliveryTicks(messageId: sent.id, conversationId: "c1")

        XCTAssertEqual(ticked.deliveryState, .read)
    }

    func test_simulateDeliveryTicks_stopsAtDeliveredWhenReceiptsDisabled() async throws {
        let store = MockDataStore()
        let api = MockAPIClient(store: store, environment: testEnvironment)
        let repository = ChatRepository(api: api)
        _ = try await repository.updateSettings(conversationId: "c1", readReceiptsEnabled: false, disappearingDuration: nil)
        let sent = try await repository.sendMessage(text: "Ping", conversationId: "c1", replyToMessageId: nil)

        let ticked = try await repository.simulateDeliveryTicks(messageId: sent.id, conversationId: "c1")

        XCTAssertEqual(ticked.deliveryState, .delivered)
    }

    func test_simulateIncomingReply_forDirectConversation_returnsMessageFromOtherParticipant() async throws {
        let store = MockDataStore()
        let api = MockAPIClient(store: store, environment: testEnvironment)
        let repository = ChatRepository(api: api)
        let conversation = try await repository.conversation(id: "c1")

        let reply = try await repository.simulateIncomingReply(conversationId: "c1")

        XCTAssertTrue(conversation.participantIds.contains(reply.senderId))
        XCTAssertNotEqual(reply.senderId, "u1")
    }

    func test_disappearingMessage_isExcludedFromHistoryAfterExpiry() async throws {
        let store = MockDataStore()
        let api = MockAPIClient(store: store, environment: testEnvironment)
        let repository = ChatRepository(api: api)
        _ = try await repository.updateSettings(conversationId: "c1", readReceiptsEnabled: true, disappearingDuration: 1)

        let sent = try await repository.sendMessage(text: "Self-destructing", conversationId: "c1", replyToMessageId: nil)
        try await Task.sleep(nanoseconds: 1_200_000_000)

        let page = try await repository.messages(conversationId: "c1", cursor: nil)
        XCTAssertFalse(page.items.contains { $0.id == sent.id })
    }

    // MARK: - Groups
    // Seed data: c5 "Design Team" has u1 (the demo current user) as owner.
    // c3 "Weekend Trip" has u1 as a plain member — used for permission-denied checks.

    func test_createGroup_setsCurrentUserAsOwner() async throws {
        let store = MockDataStore()
        let api = MockAPIClient(store: store, environment: testEnvironment)
        let repository = ChatRepository(api: api)

        let group = try await repository.createGroup(title: "Book Club", description: "Monthly reads", memberIds: ["u2", "u3"])

        XCTAssertEqual(group.kind, .group)
        XCTAssertEqual(group.role(of: "u1"), .owner)
        XCTAssertEqual(Set(group.participantIds), ["u1", "u2", "u3"])
        XCTAssertEqual(group.groupDescription, "Monthly reads")
    }

    func test_addMember_asOwner_succeeds() async throws {
        let store = MockDataStore()
        let api = MockAPIClient(store: store, environment: testEnvironment)
        let repository = ChatRepository(api: api)

        let updated = try await repository.addMember("u3", to: "c5")

        XCTAssertTrue(updated.participantIds.contains("u3"))
        XCTAssertEqual(updated.role(of: "u3"), .member)
    }

    func test_addMember_asNonAdmin_throws() async throws {
        let store = MockDataStore()
        let api = MockAPIClient(store: store, environment: testEnvironment)
        let repository = ChatRepository(api: api)

        do {
            _ = try await repository.addMember("u3", to: "c3")
            XCTFail("Expected permission error")
        } catch {
            // expected — u1 is a plain member of c3
        }
    }

    func test_removeMember_asOwner_succeeds() async throws {
        let store = MockDataStore()
        let api = MockAPIClient(store: store, environment: testEnvironment)
        let repository = ChatRepository(api: api)

        let updated = try await repository.removeMember("u6", from: "c5")

        XCTAssertFalse(updated.participantIds.contains("u6"))
    }

    func test_removeMember_self_succeedsEvenWithoutAdminRole() async throws {
        let store = MockDataStore()
        let api = MockAPIClient(store: store, environment: testEnvironment)
        let repository = ChatRepository(api: api)

        let updated = try await repository.removeMember("u1", from: "c3")

        XCTAssertFalse(updated.participantIds.contains("u1"))
    }

    func test_removeMember_cannotRemoveOwner() async throws {
        let store = MockDataStore()
        let api = MockAPIClient(store: store, environment: testEnvironment)
        let repository = ChatRepository(api: api)

        do {
            _ = try await repository.removeMember("u1", from: "c5") // u1 is owner of c5
            XCTFail("Expected an error removing the owner")
        } catch {
            // expected
        }
    }

    func test_updateMemberRole_promotesToAdmin() async throws {
        let store = MockDataStore()
        let api = MockAPIClient(store: store, environment: testEnvironment)
        let repository = ChatRepository(api: api)

        let updated = try await repository.updateMemberRole("u6", role: .admin, in: "c5")

        XCTAssertEqual(updated.role(of: "u6"), .admin)
    }

    func test_updateGroupInfo_asAdmin_updatesTitleAndDescription() async throws {
        let store = MockDataStore()
        let api = MockAPIClient(store: store, environment: testEnvironment)
        let repository = ChatRepository(api: api)

        let updated = try await repository.updateGroupInfo(conversationId: "c5", title: "Design Guild", description: "Renamed")

        XCTAssertEqual(updated.title, "Design Guild")
        XCTAssertEqual(updated.groupDescription, "Renamed")
    }

    func test_updateGroupInfo_asNonAdmin_throws() async throws {
        let store = MockDataStore()
        let api = MockAPIClient(store: store, environment: testEnvironment)
        let repository = ChatRepository(api: api)

        do {
            _ = try await repository.updateGroupInfo(conversationId: "c3", title: "Hijacked", description: nil)
            XCTFail("Expected permission error")
        } catch {
            // expected
        }
    }

    func test_setPinnedMessage_inGroup_requiresAdmin() async throws {
        let store = MockDataStore()
        let api = MockAPIClient(store: store, environment: testEnvironment)
        let repository = ChatRepository(api: api)

        let pinned = try await repository.setPinnedMessage("m12", in: "c5")
        XCTAssertEqual(pinned.pinnedMessageId, "m12")

        do {
            _ = try await repository.setPinnedMessage("m8", in: "c3")
            XCTFail("Expected permission error for non-admin pin attempt")
        } catch {
            // expected
        }
    }

    func test_setMuted_persists() async throws {
        let store = MockDataStore()
        let api = MockAPIClient(store: store, environment: testEnvironment)
        let repository = ChatRepository(api: api)

        let updated = try await repository.setMuted(true, for: "c1")

        XCTAssertTrue(updated.isMuted)
    }
}
