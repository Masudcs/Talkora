@testable import Talkora
import Foundation
@testable import Core

final class StubChannelRepository: IChannelRepository {
    var allChannelsResult: Result<[Channel], Error> = .success([])
    var myChannelsResult: Result<[Channel], Error> = .success([])
    var channelResult: Result<Channel, Error> = .failure(StubFailure.notConfigured)
    var createChannelResult: Result<Channel, Error> = .failure(StubFailure.notConfigured)
    var followResult: Result<Channel, Error> = .failure(StubFailure.notConfigured)
    var unfollowResult: Result<Channel, Error> = .failure(StubFailure.notConfigured)
    var postsResult: Result<[ChannelPost], Error> = .success([])
    var createPostResult: Result<ChannelPost, Error> = .failure(StubFailure.notConfigured)
    var registerViewResult: Result<ChannelPost, Error> = .failure(StubFailure.notConfigured)
    var communitiesResult: Result<[Community], Error> = .success([])
    var communityResult: Result<Community, Error> = .failure(StubFailure.notConfigured)
    var createCommunityResult: Result<Community, Error> = .failure(StubFailure.notConfigured)
    var linkGroupResult: Result<Community, Error> = .failure(StubFailure.notConfigured)
    var linkChannelResult: Result<Community, Error> = .failure(StubFailure.notConfigured)

    func allChannels() async throws -> [Channel] { try allChannelsResult.get() }
    func myChannels() async throws -> [Channel] { try myChannelsResult.get() }
    func channel(id: String) async throws -> Channel { try channelResult.get() }
    func createChannel(title: String, description: String?) async throws -> Channel { try createChannelResult.get() }
    func follow(_ channelId: String) async throws -> Channel { try followResult.get() }
    func unfollow(_ channelId: String) async throws -> Channel { try unfollowResult.get() }
    func posts(channelId: String) async throws -> [ChannelPost] { try postsResult.get() }
    func createPost(channelId: String, text: String) async throws -> ChannelPost { try createPostResult.get() }
    func registerView(postId: String, channelId: String) async throws -> ChannelPost { try registerViewResult.get() }
    func communities() async throws -> [Community] { try communitiesResult.get() }
    func community(id: String) async throws -> Community { try communityResult.get() }
    func createCommunity(title: String, description: String?) async throws -> Community { try createCommunityResult.get() }
    func linkGroup(_ conversationId: String, toCommunity communityId: String) async throws -> Community { try linkGroupResult.get() }
    func linkChannel(_ channelId: String, toCommunity communityId: String) async throws -> Community { try linkChannelResult.get() }
}
