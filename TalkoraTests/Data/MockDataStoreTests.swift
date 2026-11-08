@testable import Talkora
import XCTest
@testable import Core
@testable import Mock

final class MockDataStoreTests: XCTestCase {
    func test_allConversations_sortedByMostRecentlyUpdated() async {
        let store = MockDataStore()
        let conversations = await store.allConversations()

        XCTAssertFalse(conversations.isEmpty)
        let updatedDates = conversations.map(\.updatedAt)
        XCTAssertEqual(updatedDates, updatedDates.sorted(by: >))
    }

    func test_appendMessage_persistsAndUpdatesConversationPreview() async {
        let store = MockDataStore()
        let newMessage = MessageDTO(
            id: "test-1",
            conversationId: "c1",
            senderId: "u1",
            text: "New test message",
            createdAt: "2025-01-01T00:00:00Z"
        )

        await store.appendMessage(newMessage)

        let page = await store.messagesPage(conversationId: "c1", cursor: nil, pageSize: 100)
        XCTAssertTrue(page.items.contains(newMessage))

        let conversation = await store.conversation(id: "c1")
        XCTAssertEqual(conversation?.lastMessagePreview, "New test message")
    }

    func test_messagesPage_respectsCursorAndPageSize() async {
        let store = MockDataStore()
        let firstPage = await store.messagesPage(conversationId: "c1", cursor: nil, pageSize: 2)

        XCTAssertEqual(firstPage.items.count, 2)
        XCTAssertTrue(firstPage.hasMore)
        XCTAssertNotNil(firstPage.nextCursor)

        let secondPage = await store.messagesPage(conversationId: "c1", cursor: firstPage.nextCursor, pageSize: 2)
        XCTAssertFalse(secondPage.hasMore)
        XCTAssertFalse(secondPage.items.isEmpty)
    }
}
