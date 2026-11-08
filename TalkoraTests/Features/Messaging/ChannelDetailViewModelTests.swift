@testable import Talkora
import Foundation
import XCTest
@testable import Core
@testable import Messaging

private func makeUser(_ id: String, handle: String? = nil) -> User {
    User(id: id, displayName: id.capitalized, handle: handle ?? "@\(id)", avatarURL: nil, status: .online, createdAt: Date())
}

private func makeChannel(_ id: String, owner: String = "owner", admins: [String] = [], following: Bool = false) -> Channel {
    Channel(id: id, title: "Channel \(id)", description: nil, ownerId: owner, adminIds: admins,
            followerCount: 1, isFollowing: following, createdAt: Date())
}

private func makePost(_ id: String, channel: String = "c1", author: String = "owner", views: Int = 0) -> ChannelPost {
    ChannelPost(id: id, channelId: channel, authorId: author, text: "post \(id)", createdAt: Date(), viewCount: views)
}

@MainActor
private func waitUntil(timeout: TimeInterval = 3, _ condition: () -> Bool) async {
    let deadline = Date().addingTimeInterval(timeout)
    while !condition() && Date() < deadline {
        try? await Task.sleep(nanoseconds: 20_000_000)
    }
}

@MainActor
final class ChannelDetailViewModelTests: XCTestCase {
    private func makeViewModel(_ channels: StubChannelRepository, _ users: StubUserRepository) -> ChannelDetailViewModel {
        ChannelDetailViewModel(channelId: "c1", repository: channels, userRepository: users)
    }

    func test_load_success_populatesChannelPostsAndAuthors() async {
        let channels = StubChannelRepository()
        channels.channelResult = .success(makeChannel("c1", owner: "me"))
        channels.postsResult = .success([makePost("p1", author: "bob")])
        let users = StubUserRepository()
        users.currentUserResult = .success(makeUser("me"))
        users.userResult = .success(makeUser("bob"))
        let viewModel = makeViewModel(channels, users)

        await viewModel.load()

        XCTAssertEqual(viewModel.channel?.id, "c1")
        XCTAssertEqual(viewModel.posts.map(\.id), ["p1"])
        XCTAssertEqual(viewModel.author(for: makePost("p1", author: "bob"))?.id, "bob")
        XCTAssertTrue(viewModel.isAdmin)
    }

    func test_load_noPosts_setsEmptyState() async {
        let channels = StubChannelRepository()
        channels.channelResult = .success(makeChannel("c1"))
        let users = StubUserRepository()
        users.currentUserResult = .success(makeUser("me"))
        let viewModel = makeViewModel(channels, users)

        await viewModel.load()

        guard case .empty = viewModel.postsState else { return XCTFail("expected empty, got \(viewModel.postsState)") }
        XCTAssertFalse(viewModel.isAdmin)
    }

    func test_load_channelFailure_setsFailedState() async {
        let users = StubUserRepository()
        users.currentUserResult = .success(makeUser("me"))
        let viewModel = makeViewModel(StubChannelRepository(), users)

        await viewModel.load()

        XCTAssertNotNil(viewModel.postsState.error)
    }

    func test_load_currentUserFailure_setsFailedState() async {
        let channels = StubChannelRepository()
        channels.channelResult = .success(makeChannel("c1"))
        let viewModel = makeViewModel(channels, StubUserRepository())

        await viewModel.load()

        XCTAssertNotNil(viewModel.postsState.error)
    }

    func test_toggleFollow_whenNotFollowing_updatesChannelFromFollowResult() async {
        let channels = StubChannelRepository()
        channels.channelResult = .success(makeChannel("c1", following: false))
        channels.followResult = .success(makeChannel("c1", following: true))
        let users = StubUserRepository()
        users.currentUserResult = .success(makeUser("me"))
        let viewModel = makeViewModel(channels, users)
        await viewModel.load()

        await viewModel.toggleFollow()

        XCTAssertEqual(viewModel.channel?.isFollowing, true)
    }

    func test_toggleFollow_whenFollowing_updatesChannelFromUnfollowResult() async {
        let channels = StubChannelRepository()
        channels.channelResult = .success(makeChannel("c1", following: true))
        channels.unfollowResult = .success(makeChannel("c1", following: false))
        let users = StubUserRepository()
        users.currentUserResult = .success(makeUser("me"))
        let viewModel = makeViewModel(channels, users)
        await viewModel.load()

        await viewModel.toggleFollow()

        XCTAssertEqual(viewModel.channel?.isFollowing, false)
    }

    func test_toggleFollow_failure_keepsChannelUnchanged() async {
        let channels = StubChannelRepository()
        channels.channelResult = .success(makeChannel("c1", following: false))
        let users = StubUserRepository()
        users.currentUserResult = .success(makeUser("me"))
        let viewModel = makeViewModel(channels, users)
        await viewModel.load()

        await viewModel.toggleFollow()

        XCTAssertEqual(viewModel.channel?.isFollowing, false)
    }

    func test_post_success_prependsPostAndClearsDraft() async {
        let channels = StubChannelRepository()
        channels.channelResult = .success(makeChannel("c1"))
        channels.postsResult = .success([makePost("p1")])
        channels.createPostResult = .success(makePost("p2"))
        let users = StubUserRepository()
        users.currentUserResult = .success(makeUser("me"))
        users.userResult = .success(makeUser("owner"))
        let viewModel = makeViewModel(channels, users)
        await viewModel.load()
        viewModel.draftText = "  hello  "

        await viewModel.post()

        XCTAssertEqual(viewModel.posts.map(\.id), ["p2", "p1"])
        XCTAssertEqual(viewModel.draftText, "")
        XCTAssertNil(viewModel.actionError)
    }

    func test_post_blankDraft_doesNothing() async {
        let channels = StubChannelRepository()
        channels.createPostResult = .success(makePost("p2"))
        let viewModel = makeViewModel(channels, StubUserRepository())
        viewModel.draftText = "   "

        await viewModel.post()

        XCTAssertTrue(viewModel.posts.isEmpty)
        XCTAssertEqual(viewModel.draftText, "   ")
    }

    func test_post_failure_setsActionError() async {
        let viewModel = makeViewModel(StubChannelRepository(), StubUserRepository())
        viewModel.draftText = "hello"

        await viewModel.post()

        XCTAssertNotNil(viewModel.actionError)
        XCTAssertTrue(viewModel.posts.isEmpty)
    }

    func test_registerView_success_replacesPostWithUpdatedViewCount() async {
        let channels = StubChannelRepository()
        channels.channelResult = .success(makeChannel("c1"))
        channels.postsResult = .success([makePost("p1", views: 0)])
        channels.registerViewResult = .success(makePost("p1", views: 5))
        let users = StubUserRepository()
        users.currentUserResult = .success(makeUser("me"))
        users.userResult = .success(makeUser("owner"))
        let viewModel = makeViewModel(channels, users)
        await viewModel.load()

        viewModel.registerView(makePost("p1"))
        await waitUntil { viewModel.posts.first?.viewCount == 5 }

        XCTAssertEqual(viewModel.posts.first?.viewCount, 5)
    }
}
