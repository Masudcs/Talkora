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

@MainActor
final class ChannelDirectoryViewModelTests: XCTestCase {
    func test_load_success_splitsMineFromDiscoverableAndLoadsCommunities() async {
        let stub = StubChannelRepository()
        stub.myChannelsResult = .success([makeChannel("a", following: true)])
        stub.allChannelsResult = .success([makeChannel("a", following: true), makeChannel("b")])
        stub.communitiesResult = .success([makeCommunity()])
        let viewModel = ChannelDirectoryViewModel(repository: stub)

        await viewModel.load()

        XCTAssertEqual(viewModel.myChannels.map(\.id), ["a"])
        XCTAssertEqual(viewModel.discoverableChannels.map(\.id), ["b"])
        XCTAssertEqual(viewModel.communities.map(\.id), ["com1"])
        XCTAssertEqual(viewModel.state.value, true)
    }

    func test_load_failure_setsFailedState() async {
        let stub = StubChannelRepository()
        stub.allChannelsResult = .failure(StubFailure.notConfigured)
        let viewModel = ChannelDirectoryViewModel(repository: stub)

        await viewModel.load()

        XCTAssertNotNil(viewModel.state.error)
    }

    func test_toggleFollow_reloadsDirectory() async {
        let stub = StubChannelRepository()
        stub.followResult = .success(makeChannel("b", following: true))
        stub.allChannelsResult = .success([makeChannel("b")])
        let viewModel = ChannelDirectoryViewModel(repository: stub)
        await viewModel.load()
        XCTAssertTrue(viewModel.myChannels.isEmpty)

        stub.myChannelsResult = .success([makeChannel("b", following: true)])
        await viewModel.toggleFollow(makeChannel("b"))

        XCTAssertEqual(viewModel.myChannels.map(\.id), ["b"])
        XCTAssertTrue(viewModel.discoverableChannels.isEmpty)
    }

    func test_createChannel_success_returnsChannelAndReloads() async {
        let stub = StubChannelRepository()
        stub.createChannelResult = .success(makeChannel("new"))
        stub.myChannelsResult = .success([makeChannel("new")])
        stub.allChannelsResult = .success([makeChannel("new")])
        let viewModel = ChannelDirectoryViewModel(repository: stub)

        let created = await viewModel.createChannel(title: "New", description: nil)

        XCTAssertEqual(created?.id, "new")
        XCTAssertEqual(viewModel.myChannels.map(\.id), ["new"])
    }

    func test_createChannel_failure_returnsNil() async {
        let viewModel = ChannelDirectoryViewModel(repository: StubChannelRepository())

        let created = await viewModel.createChannel(title: "New", description: nil)

        XCTAssertNil(created)
    }

    func test_createCommunity_success_returnsCommunityAndReloads() async {
        let stub = StubChannelRepository()
        stub.createCommunityResult = .success(makeCommunity("new"))
        stub.communitiesResult = .success([makeCommunity("new")])
        let viewModel = ChannelDirectoryViewModel(repository: stub)

        let created = await viewModel.createCommunity(title: "New", description: nil)

        XCTAssertEqual(created?.id, "new")
        XCTAssertEqual(viewModel.communities.map(\.id), ["new"])
    }

    func test_createCommunity_failure_returnsNil() async {
        let viewModel = ChannelDirectoryViewModel(repository: StubChannelRepository())

        let created = await viewModel.createCommunity(title: "New", description: nil)

        XCTAssertNil(created)
    }
}
