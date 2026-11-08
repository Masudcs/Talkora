import SwiftUI
import Core
import Messaging
import CommonUI

/// Contacts tab (public: embedded by the app shell). Hub for discoverability, the add-contact flows, pending requests and the connection list; tapping a connection opens (or creates) the direct chat.
public struct ContactsScreen: View {
    @State private var viewModel: ContactsViewModel
    @State private var isShowingDiscoverabilityPicker = false
    /// The tab's controller, used to push the add-contact flows and chat threads.
    @State private var navController = NavController()

    init(viewModel: ContactsViewModel) {
        _viewModel = State(wrappedValue: viewModel)
    }

    public init() {
        self.init(viewModel: ContactsViewModel())
    }

    public var body: some View {
        NavigationStack(path: $navController.navStack) {
            List {
                Section {
                    Button {
                        isShowingDiscoverabilityPicker = true
                    } label: {
                        DiscoverabilityRow(value: viewModel.discoverability)
                    }
                    .buttonStyle(.plain)
                } footer: {
                    Text("Controls who can find you by username, QR code, or synced contacts.")
                }

                Section {
                    PushRowButton {
                        navController.navigateTo(Destination.SearchUsers())
                    } label: {
                        Label("Search by Username", systemImage: "magnifyingglass")
                    }
                    PushRowButton {
                        navController.navigateTo(Destination.MyQRCode())
                    } label: {
                        Label("My QR Code", systemImage: "qrcode")
                    }
                    PushRowButton {
                        navController.navigateTo(Destination.ScanQR())
                    } label: {
                        Label("Scan QR Code", systemImage: "qrcode.viewfinder")
                    }
                    PushRowButton {
                        navController.navigateTo(Destination.DeviceContacts())
                    } label: {
                        Label("Sync Contacts", systemImage: "person.crop.circle.badge.plus")
                    }
                }

                Section {
                    PushRowButton {
                        navController.navigateTo(Destination.IncomingRequests())
                    } label: {
                        HStack {
                            Label("Requests", systemImage: "person.badge.clock")
                            Spacer()
                            if viewModel.incomingRequestCount > 0 {
                                Text("\(viewModel.incomingRequestCount)")
                                    .font(.caption.bold())
                                    .padding(6)
                                    .background(Color.accentColor)
                                    .foregroundStyle(.white)
                                    .clipShape(Circle())
                            }
                        }
                    }
                    Button {
                        // Demo-only: fabricates a request so the Requests flow can be shown without a second device.
                        Task { await viewModel.simulateIncomingRequest() }
                    } label: {
                        Label("Simulate Incoming Request", systemImage: "person.badge.plus")
                    }
                    .font(Font.caption)
                }

                if !viewModel.connections.isEmpty {
                    Section("My Contacts") {
                        ForEach(viewModel.connections) { user in
                            Button {
                                Task {
                                    // Navigate only after the conversation id is resolved, then clear it so returning to this screen does not re-push the chat.
                                    await viewModel.startChat(with: user)
                                    if let id = viewModel.navigateToConversationId {
                                        navController.navigateTo(Destination.ChatThread(conversationId: id))
                                        viewModel.clearNavigation()
                                    }
                                }
                            } label: {
                                HStack(spacing: 16) {
                                    TalkoraAvatar(name: user.displayName, size: 40)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(user.displayName)
                                            .foregroundStyle(Color.primary)
                                        Text(user.handle)
                                            .font(Font.caption)
                                            .foregroundStyle(Color.secondary)
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .navigationTitle("Contacts")
            .task { await viewModel.load() }
            .sheet(isPresented: $isShowingDiscoverabilityPicker) {
                DiscoverabilityPickerView(current: viewModel.discoverability) { newValue in
                    Task { await viewModel.updateDiscoverability(newValue) }
                }
            }
            .navigationDestination(for: BaseDestination.self) { destination in
                destination.getScreen(navController: navController)
            }
        }
    }
}

/// Summary row for the "who can find me" setting; tapping it opens `DiscoverabilityPickerView`.
private struct DiscoverabilityRow: View {
    let value: DiscoverabilityPrivacy

    var body: some View {
        HStack {
            Label("Who Can Find Me", systemImage: "eye")
            Spacer()
            Text(label).foregroundStyle(Color.secondary)
        }
    }

    private var label: String {
        switch value {
        case .everyone: return "Everyone"
        case .contactsOnly: return "My Contacts"
        case .nobody: return "Nobody"
        }
    }
}

/// Sheet for choosing discoverability. Keeps a local `selection` and reports it through `onSelect` only when Done is tapped, so dismissing otherwise changes nothing.
struct DiscoverabilityPickerView: View {
    let current: DiscoverabilityPrivacy
    let onSelect: (DiscoverabilityPrivacy) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var selection: DiscoverabilityPrivacy

    init(current: DiscoverabilityPrivacy, onSelect: @escaping (DiscoverabilityPrivacy) -> Void) {
        self.current = current
        self.onSelect = onSelect
        _selection = State(initialValue: current)
    }

    var body: some View {
        NavigationStack {
            Form {
                Picker("Who can find me", selection: $selection) {
                    Text("Everyone").tag(DiscoverabilityPrivacy.everyone)
                    Text("My Contacts").tag(DiscoverabilityPrivacy.contactsOnly)
                    Text("Nobody").tag(DiscoverabilityPrivacy.nobody)
                }
                .pickerStyle(.inline)
            }
            .navigationTitle("Who Can Find Me")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        onSelect(selection)
                        dismiss()
                    }
                }
            }
        }
    }
}

#if DEBUG
#Preview("Loaded") {
    ContactsScreen(viewModel: ContactsViewModel(previewScenario: .loaded))
}

#Preview("Empty") {
    ContactsScreen(viewModel: ContactsViewModel(previewScenario: .empty))
}
#endif
