@testable import Talkora
import Foundation
import XCTest
@testable import Core
@testable import Messaging

private func makeChannel(_ id: String, owner: String = "owner", admins: [String] = [], following: Bool = false) -> Channel {
    Channel(id: id, title: "Channel \(id)", description: nil, ownerId: owner, adminIds: admins,
            followerCount: 1, isFollowing: following, createdAt: Date())
}

private func makeCommunity(_ id: String = "com1", linked: [CommunityLinkedItem] = []) -> Community {
    Community(id: id, title: "Community \(id)", description: nil, ownerId: "owner", memberIds: ["owner"],
              linkedItems: linked, createdAt: Date())
}

private func makeConversation(_ id: String, kind: ConversationKind) -> Conversation {
    Conversation(id: id, kind: kind, title: "Conv \(id)", participantIds: ["me"], lastMessagePreview: nil, updatedAt: Date())
}

@MainActor
final class CommunityDetailViewModelTests: XCTestCase {
    private func makeViewModel(_ channels: StubChannelRepository, _ chats: StubChatRepository) -> CommunityDetailViewModel {
        CommunityDetailViewModel(communityId: "com1", channelRepository: channels, chatRepository: chats)
    }

    func test_load_success_excludesAlreadyLinkedItemsAndDirectChats() async {
        let channels = StubChannelRepository()
        channels.communityResult = .success(makeCommunity(linked: [
            CommunityLinkedItem(itemId: "g1", kind: .group, title: "G1"),
            CommunityLinkedItem(itemId: "c1", kind: .channel, title: "C1")
        ]))
        channels.allChannelsResult = .success([makeChannel("c1"), makeChannel("c2")])
        let chats = StubChatRepository()
        chats.conversationsResult = .success([
            makeConversation("g1", kind: .group),
            makeConversation("g2", kind: .group),
            makeConversation("d1", kind: .direct)
        ])
        let viewModel = makeViewModel(channels, chats)

        await viewModel.load()

        XCTAssertEqual(viewModel.community?.id, "com1")
        XCTAssertEqual(viewModel.linkableGroups.map(\.id), ["g2"])
        XCTAssertEqual(viewModel.linkableChannels.map(\.id), ["c2"])
        XCTAssertNil(viewModel.actionError)
    }

    func test_load_failure_setsActionError() async {
        let viewModel = makeViewModel(StubChannelRepository(), StubChatRepository())

        await viewModel.load()

        XCTAssertNil(viewModel.community)
        XCTAssertNotNil(viewModel.actionError)
    }

    func test_linkGroup_success_updatesCommunityAndLinkableGroups() async {
        let channels = StubChannelRepository()
        channels.communityResult = .success(makeCommunity())
        let chats = StubChatRepository()
        let group = makeConversation("g1", kind: .group)
        chats.conversationsResult = .success([group])
        let viewModel = makeViewModel(channels, chats)
        await viewModel.load()
        XCTAssertEqual(viewModel.linkableGroups.map(\.id), ["g1"])

        channels.linkGroupResult = .success(makeCommunity(linked: [CommunityLinkedItem(itemId: "g1", kind: .group, title: "G1")]))
        await viewModel.linkGroup(group)

        XCTAssertEqual(viewModel.community?.linkedItems.map(\.itemId), ["g1"])
        XCTAssertTrue(viewModel.linkableGroups.isEmpty)
    }

    func test_linkChannel_success_updatesCommunityAndLinkableChannels() async {
        let channels = StubChannelRepository()
        channels.communityResult = .success(makeCommunity())
        channels.allChannelsResult = .success([makeChannel("c1")])
        let viewModel = makeViewModel(channels, StubChatRepository())
        await viewModel.load()
        XCTAssertEqual(viewModel.linkableChannels.map(\.id), ["c1"])

        channels.linkChannelResult = .success(makeCommunity(linked: [CommunityLinkedItem(itemId: "c1", kind: .channel, title: "C1")]))
        await viewModel.linkChannel(makeChannel("c1"))

        XCTAssertEqual(viewModel.community?.linkedItems.map(\.itemId), ["c1"])
        XCTAssertTrue(viewModel.linkableChannels.isEmpty)
    }

    func test_linkGroup_failure_keepsCommunityUnchanged() async {
        let channels = StubChannelRepository()
        channels.communityResult = .success(makeCommunity())
        let chats = StubChatRepository()
        let group = makeConversation("g1", kind: .group)
        chats.conversationsResult = .success([group])
        let viewModel = makeViewModel(channels, chats)
        await viewModel.load()

        await viewModel.linkGroup(group)

        XCTAssertTrue(viewModel.community?.linkedItems.isEmpty ?? false)
        XCTAssertEqual(viewModel.linkableGroups.map(\.id), ["g1"])
    }
}
