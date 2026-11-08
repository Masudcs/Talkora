import Foundation
import Observation
import Core
import Mock

@MainActor
@Observable
final class ChannelDetailViewModel {
    @ObservationIgnored private var isPreview = false
    let channelId: String
    private(set) var channel: Channel?
    private(set) var authors: [String: User] = [:]
    private(set) var postsState: LoadableState<[ChannelPost]> = .idle
    private(set) var currentUserId: String = ""
    var draftText: String = ""
    private(set) var actionError: AppError?

    private let repository: IChannelRepository
    private let userRepository: IUserRepository

    init(channelId: String, repository: IChannelRepository = ChannelRepository(), userRepository: IUserRepository = UserRepository()) {
        self.channelId = channelId
        self.repository = repository
        self.userRepository = userRepository
    }

    var posts: [ChannelPost] {
        postsState.value ?? []
    }

    var isAdmin: Bool {
        guard let channel else { return false }
        return channel.isAdmin(currentUserId)
    }

    func author(for post: ChannelPost) -> User? {
        authors[post.authorId]
    }

    func load() async {
        guard !isPreview else { return }
        postsState = .loading
        do {
            currentUserId = try await userRepository.currentUser().id
            channel = try await repository.channel(id: channelId)
            let items = try await repository.posts(channelId: channelId)
            postsState = items.isEmpty ? .empty : .loaded(items)
            var fetchedAuthors = authors
            for authorId in Set(items.map(\.authorId)) where fetchedAuthors[authorId] == nil {
                if let user = try? await userRepository.user(id: authorId) {
                    fetchedAuthors[authorId] = user
                }
            }
            authors = fetchedAuthors
        } catch {
            postsState = .failed(error.asAppError)
        }
    }

    func toggleFollow() async {
        guard let channel else { return }
        if let updated = try? await (channel.isFollowing ? repository.unfollow(channel.id) : repository.follow(channel.id)) {
            self.channel = updated
        }
    }

    func post() async {
        let text = draftText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        draftText = ""
        do {
            let post = try await repository.createPost(channelId: channelId, text: text)
            var current = posts
            current.insert(post, at: 0)
            postsState = .loaded(current)
        } catch {
            actionError = error.asAppError
        }
    }

    /// Called once per post appearance to register a unique view — mirrors the
    /// server-side dedup in `MockDataStore.registerPostView`.
    func registerView(_ post: ChannelPost) {
        Task {
            if let updated = try? await repository.registerView(postId: post.id, channelId: channelId) {
                var current = posts
                if let index = current.firstIndex(where: { $0.id == updated.id }) {
                    current[index] = updated
                    postsState = .loaded(current)
                }
            }
        }
    }
}

#if DEBUG
extension ChannelDetailViewModel {
    convenience init(previewScenario scenario: PreviewScenario, isAdmin: Bool = false) {
        let channel = isAdmin ? PreviewData.adminChannel : PreviewData.followerChannel
        self.init(channelId: channel.id)
        isPreview = true
        currentUserId = PreviewData.currentUser.id
        self.channel = channel
        authors = Dictionary(uniqueKeysWithValues: PreviewData.users.map { ($0.id, $0) })
        postsState = scenario.state(PreviewData.channelPosts(in: channel.id))
    }
}
#endif
