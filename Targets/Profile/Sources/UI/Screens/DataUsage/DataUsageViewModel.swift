import Foundation
import Observation
import Core

/// One row of the storage breakdown: total attachment bytes for a media kind.
struct StorageBreakdownItem: Identifiable {
    let id: MediaKind
    let label: String
    let bytes: Int
}

/// Backs `DataUsageScreen`: sums attachment sizes per media kind across conversations and prepares the JSON data export.
@MainActor
@Observable
final class DataUsageViewModel {
    /// Preview-only flag that makes `load()` a no-op so seeded state isn't overwritten. `@ObservationIgnored` because the UI never reads it.
    @ObservationIgnored private var isPreview = false
    private(set) var statsState: LoadableState<[StorageBreakdownItem]> = .idle
    /// Location of the prepared export; nil until preparation finishes (or if it failed), which the screen shows as "Preparing export".
    private(set) var exportFileURL: URL?

    private let chatRepository: IChatRepository
    private let mediaRepository: IMediaRepository
    private let userRepository: IUserRepository

    init(chatRepository: IChatRepository = ChatRepository(), mediaRepository: IMediaRepository = MediaRepository(), userRepository: IUserRepository = UserRepository()) {
        self.chatRepository = chatRepository
        self.mediaRepository = mediaRepository
        self.userRepository = userRepository
    }

    var totalBytes: Int {
        (statsState.value ?? []).reduce(0) { $0 + $1.bytes }
    }

    /// Runs the storage scan and export preparation concurrently.
    func load() async {
        guard !isPreview else { return }
        async let stats: Void = loadStorageStats()
        async let export: Void = prepareExport()
        _ = await (stats, export)
    }

    /// Only a failure to list conversations fails the screen; a conversation whose media can't be loaded is skipped, so totals may undercount. Rows are sorted largest first.
    private func loadStorageStats() async {
        statsState = .loading
        let conversations: [Conversation]
        do {
            conversations = try await chatRepository.conversations()
        } catch {
            statsState = .failed(error.asAppError)
            return
        }
        var totals: [MediaKind: Int] = [:]
        for conversation in conversations {
            guard let messages = try? await mediaRepository.mediaHistory(conversationId: conversation.id) else { continue }
            for message in messages {
                guard let attachment = message.attachment else { continue }
                totals[attachment.kind, default: 0] += attachment.sizeBytes
            }
        }
        let breakdown = totals.map { StorageBreakdownItem(id: $0.key, label: Self.label(for: $0.key), bytes: $0.value) }
            .sorted { $0.bytes > $1.bytes }
        statsState = breakdown.isEmpty ? .empty : .loaded(breakdown)
    }

    private static func label(for kind: MediaKind) -> String {
        switch kind {
        case .image: "Photos"
        case .video: "Videos"
        case .file: "Files"
        }
    }

    /// Improve: prepared proactively on load, not on tap — by the time the user taps
    /// "Export My Data" the file already exists, so it's genuinely a single tap to share.
    private func prepareExport() async {
        guard let user = try? await userRepository.currentUser(),
              let conversations = try? await chatRepository.conversations() else { return }
        var exportedConversations: [ExportedConversation] = []
        for conversation in conversations {
            // Only the first page of messages per conversation is exported, and failures are silent.
            let page = try? await chatRepository.messages(conversationId: conversation.id, cursor: nil)
            let messages = (page?.items ?? []).map {
                // Deleted messages keep their metadata but their text is blanked.
                ExportedMessage(senderId: $0.senderId, text: $0.isDeleted ? "" : $0.text, sentAt: $0.createdAt)
            }
            exportedConversations.append(ExportedConversation(title: conversation.title, messages: messages))
        }
        let payload = ExportPayload(
            exportedAt: Date(),
            displayName: user.displayName,
            handle: user.handle,
            bio: user.bio,
            conversations: exportedConversations
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(payload) else { return }
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("talkora-data-export.json")
        try? data.write(to: url, options: .atomic)
        exportFileURL = url
    }
}

/// Export file schema, kept private: the JSON layout is only produced here.
private struct ExportedMessage: Codable {
    let senderId: String
    let text: String
    let sentAt: Date
}

private struct ExportedConversation: Codable {
    let title: String
    let messages: [ExportedMessage]
}

private struct ExportPayload: Codable {
    let exportedAt: Date
    let displayName: String
    let handle: String
    let bio: String
    let conversations: [ExportedConversation]
}

#if DEBUG
extension DataUsageViewModel {
    convenience init(previewScenario scenario: PreviewScenario) {
        self.init()
        isPreview = true
        let breakdown = [
            StorageBreakdownItem(id: .video, label: "Videos", bytes: 48_500_000),
            StorageBreakdownItem(id: .image, label: "Photos", bytes: 12_300_000),
            StorageBreakdownItem(id: .file, label: "Files", bytes: 2_100_000)
        ]
        statsState = scenario.state(breakdown)
        if scenario == .loaded {
            exportFileURL = FileManager.default.temporaryDirectory.appendingPathComponent("talkora-data-export.json")
        }
    }
}
#endif
