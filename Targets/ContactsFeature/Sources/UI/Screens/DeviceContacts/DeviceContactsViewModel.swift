import Foundation
import Observation
import Core
import Mock

/// Syncs device contacts through the repository (simulated; no `CNContactStore` access or permission prompt here).
@MainActor
@Observable
final class DeviceContactsViewModel {
    @ObservationIgnored private var isPreview = false
    private(set) var state: LoadableState<[DeviceContact]> = .idle
    /// Matched user ids a request was attempted for this session; drives the "Requested" label.
    private(set) var connectedIds: Set<String> = []

    private let contactRepository: IContactRepository

    init(contactRepository: IContactRepository = ContactRepository()) {
        self.contactRepository = contactRepository
    }

    func sync() async {
        guard !isPreview else { return }
        state = .loading
        do {
            let items = try await contactRepository.syncDeviceContacts()
            state = items.isEmpty ? .empty : .loaded(items)
        } catch {
            state = .failed(error.asAppError)
        }
    }

    /// Sends a request to the matched user. Contacts without a match are ignored.
    func connect(_ contact: DeviceContact) async {
        guard let userId = contact.matchedUserId else { return }
        _ = try? await contactRepository.sendContactRequest(to: userId)
        connectedIds.insert(userId)
    }
}

#if DEBUG
extension DeviceContactsViewModel {
    convenience init(previewScenario scenario: PreviewScenario) {
        self.init()
        isPreview = true
        state = scenario.state(PreviewData.deviceContacts)
        if case .loaded = state {
            connectedIds = Set(PreviewData.deviceContacts.prefix(1).compactMap(\.matchedUserId))
        }
    }
}
#endif
