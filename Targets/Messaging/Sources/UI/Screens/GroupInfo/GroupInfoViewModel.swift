import Foundation
import Observation
import Core
import Mock

struct GroupMemberDisplay: Identifiable, Hashable {
    let user: User
    let role: GroupRole
    var id: String { user.id }
}

@MainActor
@Observable
final class GroupInfoViewModel {
    @ObservationIgnored private var isPreview = false
    let conversationId: String
    private(set) var conversation: Conversation?
    private(set) var members: [GroupMemberDisplay] = []
    private(set) var currentUserId: String = ""
    private(set) var isLoading = false
    private(set) var actionError: AppError?
    private(set) var didLeave = false

    var editedTitle: String = ""
    var editedDescription: String = ""
    var isEditingInfo = false

    private let chatRepository: IChatRepository
    private let userRepository: IUserRepository

    init(conversationId: String, chatRepository: IChatRepository = ChatRepository(), userRepository: IUserRepository = UserRepository()) {
        self.conversationId = conversationId
        self.chatRepository = chatRepository
        self.userRepository = userRepository
    }

    var isCurrentUserAdmin: Bool {
        conversation?.isAdminOrOwner(currentUserId) ?? false
    }

    func load() async {
        guard !isPreview else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            currentUserId = try await userRepository.currentUser().id
            let conv = try await chatRepository.conversation(id: conversationId)
            apply(conv)

            var fetched: [GroupMemberDisplay] = []
            for member in conv.members {
                if let user = try? await userRepository.user(id: member.userId) {
                    fetched.append(GroupMemberDisplay(user: user, role: member.role))
                }
            }
            members = fetched.sorted { lhs, rhs in
                if lhs.role != rhs.role { return rolePriority(lhs.role) < rolePriority(rhs.role) }
                return lhs.user.displayName < rhs.user.displayName
            }
        } catch {
            actionError = error.asAppError
        }
    }

    func saveInfo() async {
        let title = editedTitle.trimmingCharacters(in: .whitespaces)
        guard !title.isEmpty else { return }
        do {
            let updated = try await chatRepository.updateGroupInfo(
                conversationId: conversationId,
                title: title,
                description: editedDescription.trimmingCharacters(in: .whitespaces).isEmpty ? nil : editedDescription
            )
            apply(updated)
            isEditingInfo = false
        } catch {
            actionError = error.asAppError
        }
    }

    func promote(_ userId: String) async {
        await changeRole(userId, to: .admin)
    }

    func demote(_ userId: String) async {
        await changeRole(userId, to: .member)
    }

    func removeMember(_ userId: String) async {
        do {
            let updated = try await chatRepository.removeMember(userId, from: conversationId)
            apply(updated)
            members.removeAll { $0.id == userId }
        } catch {
            actionError = error.asAppError
        }
    }

    func leaveGroup() async {
        do {
            _ = try await chatRepository.removeMember(currentUserId, from: conversationId)
            didLeave = true
        } catch {
            actionError = error.asAppError
        }
    }

    private func changeRole(_ userId: String, to role: GroupRole) async {
        do {
            let updated = try await chatRepository.updateMemberRole(userId, role: role, in: conversationId)
            apply(updated)
            if let idx = members.firstIndex(where: { $0.id == userId }) {
                members[idx] = GroupMemberDisplay(user: members[idx].user, role: role)
            }
        } catch {
            actionError = error.asAppError
        }
    }

    private func apply(_ conversation: Conversation) {
        self.conversation = conversation
        editedTitle = conversation.title
        editedDescription = conversation.groupDescription ?? ""
    }

    private func rolePriority(_ role: GroupRole) -> Int {
        switch role {
        case .owner: return 0
        case .admin: return 1
        case .member: return 2
        }
    }
}

#if DEBUG
extension GroupInfoViewModel {
    convenience init(previewScenario scenario: PreviewScenario) {
        let conversation = PreviewData.groupConversation
        self.init(conversationId: conversation.id)
        isPreview = true
        currentUserId = PreviewData.currentUser.id
        switch scenario {
        case .loaded, .empty:
            apply(conversation)
            members = conversation.members.compactMap { member in
                PreviewData.user(member.userId).map { GroupMemberDisplay(user: $0, role: member.role) }
            }
        case .loading:
            isLoading = true
        case .failed:
            actionError = PreviewData.error
        }
    }
}
#endif
