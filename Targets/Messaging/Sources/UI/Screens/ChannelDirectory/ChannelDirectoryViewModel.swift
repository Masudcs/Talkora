import Foundation
import Observation
import Core
import Mock

@MainActor
@Observable
final class ChannelDirectoryViewModel {
    @ObservationIgnored private var isPreview = false
    private(set) var myChannels: [Channel] = []
    private(set) var discoverableChannels: [Channel] = []
    private(set) var communities: [Community] = []
    private(set) var state: LoadableState<Bool> = .idle
    var isCreateChannelPresented = false
    var isCreateCommunityPresented = false

    private let repository: IChannelRepository

    init(repository: IChannelRepository = ChannelRepository()) {
        self.repository = repository
    }

    func load() async {
        guard !isPreview else { return }
        state = .loading
        do {
            async let mine = repository.myChannels()
            async let all = repository.allChannels()
            async let communities = repository.communities()
            let mineResult = try await mine
            let allResult = try await all
            myChannels = mineResult
            let mineIds = Set(mineResult.map(\.id))
            discoverableChannels = allResult.filter { !mineIds.contains($0.id) }
            self.communities = try await communities
            state = .loaded(true)
        } catch {
            state = .failed(error.asAppError)
        }
    }

    func toggleFollow(_ channel: Channel) async {
        _ = try? await (channel.isFollowing ? repository.unfollow(channel.id) : repository.follow(channel.id))
        await load()
    }

    func createChannel(title: String, description: String?) async -> Channel? {
        guard let channel = try? await repository.createChannel(title: title, description: description) else { return nil }
        await load()
        return channel
    }

    func createCommunity(title: String, description: String?) async -> Community? {
        guard let community = try? await repository.createCommunity(title: title, description: description) else { return nil }
        await load()
        return community
    }
}

#if DEBUG
extension ChannelDirectoryViewModel {
    convenience init(previewScenario scenario: PreviewScenario) {
        self.init()
        isPreview = true
        if scenario == .loaded {
            myChannels = PreviewData.channels.filter(\.isFollowing)
            discoverableChannels = PreviewData.channels.filter { !$0.isFollowing }
            communities = PreviewData.communities
        }
        state = scenario == .failed ? .failed(PreviewData.error) : (scenario == .loading ? .loading : .loaded(true))
    }
}
#endif
