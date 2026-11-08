import Foundation
import Observation
import Core
import Mock

@MainActor
@Observable
final class CommunityDetailViewModel {
    @ObservationIgnored private var isPreview = false
    let communityId: String
    private(set) var community: Community?
    private(set) var linkableGroups: [Conversation] = []
    private(set) var linkableChannels: [Channel] = []
    var isLinkPresented = false
    private(set) var actionError: AppError?

    private let channelRepository: IChannelRepository
    private let chatRepository: IConversationRepository

    init(communityId: String, channelRepository: IChannelRepository = ChannelRepository(), chatRepository: IConversationRepository = ChatRepository()) {
        self.communityId = communityId
        self.channelRepository = channelRepository
        self.chatRepository = chatRepository
    }

    func load() async {
        guard !isPreview else { return }
        do {
            community = try await channelRepository.community(id: communityId)
            await loadLinkableItems()
        } catch {
            actionError = error.asAppError
        }
    }

    private func loadLinkableItems() async {
        guard let community else { return }
        let linkedIds = Set(community.linkedItems.map(\.itemId))
        if let conversations = try? await chatRepository.conversations() {
            linkableGroups = conversations.filter { $0.kind == .group && !linkedIds.contains($0.id) }
        }
        if let channels = try? await channelRepository.allChannels() {
            linkableChannels = channels.filter { !linkedIds.contains($0.id) }
        }
    }

    func linkGroup(_ conversation: Conversation) async {
        guard let updated = try? await channelRepository.linkGroup(conversation.id, toCommunity: communityId) else { return }
        community = updated
        await loadLinkableItems()
    }

    func linkChannel(_ channel: Channel) async {
        guard let updated = try? await channelRepository.linkChannel(channel.id, toCommunity: communityId) else { return }
        community = updated
        await loadLinkableItems()
    }
}

#if DEBUG
extension CommunityDetailViewModel {
    convenience init(forPreview: Bool = true) {
        let community = PreviewData.communities[0]
        self.init(communityId: community.id)
        isPreview = true
        self.community = community
        linkableGroups = PreviewData.conversations.filter { $0.kind == .group }
        linkableChannels = PreviewData.channels
    }
}
#endif
