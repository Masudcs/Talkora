import SwiftUI
import Core

/// Destinations owned by the Messaging module (chats, groups, bots, channels, search).
/// Other features push these by importing `Messaging`; each one resolves its own screen.
public extension Destination {
    final class ChatThread: BaseDestination {
        public let conversationId: String
        public init(conversationId: String) { self.conversationId = conversationId }
        public override var parameterKey: String { conversationId }
        public override func getScreen(navController: NavController) -> AnyView {
            AnyView(ChatThreadScreen(navController: navController, conversationId: conversationId))
        }
    }

    final class CreateGroup: BaseDestination {
        public override func getScreen(navController: NavController) -> AnyView {
            AnyView(CreateGroupScreen(navController: navController))
        }
    }

    final class GroupInfo: BaseDestination {
        public let conversationId: String
        public init(conversationId: String) { self.conversationId = conversationId }
        public override var parameterKey: String { conversationId }
        public override func getScreen(navController: NavController) -> AnyView {
            AnyView(GroupInfoScreen(navController: navController, conversationId: conversationId))
        }
    }


    final class BotDirectory: BaseDestination {
        public override func getScreen(navController: NavController) -> AnyView {
            AnyView(BotDirectoryScreen(navController: navController))
        }
    }

    final class ChannelDirectory: BaseDestination {
        public override func getScreen(navController: NavController) -> AnyView {
            AnyView(ChannelDirectoryScreen(navController: navController))
        }
    }



    /// `onJump` receives the id of the message the user picked so the presenting thread can scroll to it.
    final class InChatSearch: BaseDestination {
        public let conversationId: String
        public let onJump: (String) -> Void
        public init(conversationId: String, onJump: @escaping (String) -> Void) {
            self.conversationId = conversationId
            self.onJump = onJump
        }
        public override var parameterKey: String { conversationId }
        public override func getScreen(navController: NavController) -> AnyView {
            AnyView(InChatSearchScreen(conversationId: conversationId, onJump: onJump))
        }
    }

    /// Search results for the text typed in another screen's search field.
    final class GlobalSearch: BaseDestination {
        public let query: String
        public init(query: String) { self.query = query }
        public override var parameterKey: String { query }
        public override func getScreen(navController: NavController) -> AnyView {
            AnyView(GlobalSearchScreen(navController: navController, query: query))
        }
    }
}

/// Only pushed from within Messaging, so these stay internal.
extension Destination {
    final class AddMembers: BaseDestination {
        let conversationId: String
        init(conversationId: String) { self.conversationId = conversationId }
        override var parameterKey: String { conversationId }
        override func getScreen(navController: NavController) -> AnyView {
            AnyView(AddMembersScreen(navController: navController, conversationId: conversationId))
        }
    }

    final class ChannelDetail: BaseDestination {
        let channelId: String
        init(channelId: String) { self.channelId = channelId }
        override var parameterKey: String { channelId }
        override func getScreen(navController: NavController) -> AnyView {
            AnyView(ChannelDetailScreen(channelId: channelId))
        }
    }

    final class CommunityDetail: BaseDestination {
        let communityId: String
        init(communityId: String) { self.communityId = communityId }
        override var parameterKey: String { communityId }
        override func getScreen(navController: NavController) -> AnyView {
            AnyView(CommunityDetailScreen(navController: navController, communityId: communityId))
        }
    }
}
