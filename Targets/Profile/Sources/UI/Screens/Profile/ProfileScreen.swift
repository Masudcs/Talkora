import SwiftUI
import Core
import Payments
import Privacy
import Notifications
import CommonUI

/// Improve: a single flattened Settings tab — profile, appearance, notifications, privacy,
/// and data/storage all live one level deep, instead of scattered or nested screens.
public struct ProfileScreen: View {
    @State private var viewModel: ProfileViewModel
    // Used for pushes (Data & Storage, Wallet); sheets are presented from view-model flags instead.
    @State private var navController = NavController()

    init(viewModel: ProfileViewModel) {
        _viewModel = State(wrappedValue: viewModel)
    }

    /// Public entry point for the app's Settings tab, which can't see the internal view model.
    public init() {
        self.init(viewModel: ProfileViewModel())
    }

    public var body: some View {
        NavigationStack(path: $navController.navStack) {
            Form {
                profileHeaderSection
                appearanceSection

                Section {
                    Button {
                        viewModel.isNotificationSettingsPresented = true
                    } label: {
                        Label("Notifications", systemImage: "bell")
                    }
                    Button {
                        viewModel.isPrivacyPresented = true
                    } label: {
                        Label("Privacy & Security", systemImage: "lock.shield")
                    }
                    PushRowButton {
                        navController.navigateTo(Destination.DataUsage())
                    } label: {
                        Label("Data & Storage", systemImage: "internaldrive")
                    }
                    PushRowButton {
                        navController.navigateTo(Destination.Wallet())
                    } label: {
                        Label("Wallet", systemImage: "creditcard")
                    }
                }
                .foregroundStyle(Color.primary)

                Section {
                    Button("Sign Out", role: .destructive) {
                        viewModel.signOut()
                    }
                }
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $viewModel.isEditPresented) {
                if let user = viewModel.user {
                    EditProfileScreen(user: user) { updated in
                        viewModel.handleProfileSaved(updated)
                    }
                }
            }
            .sheet(isPresented: $viewModel.isNotificationSettingsPresented) {
                Destination.NotificationSettings().presentedScreen()
            }
            .sheet(isPresented: $viewModel.isPrivacyPresented) {
                Destination.Privacy().presentedScreen()
            }
            .task { await viewModel.load() }
            .navigationDestination(for: BaseDestination.self) { destination in
                destination.getScreen(navController: navController)
            }
        }
    }

    @ViewBuilder
    private var profileHeaderSection: some View {
        Section {
            Button {
                viewModel.isEditPresented = true
            } label: {
                HStack(spacing: 16) {
                    AsyncImage(url: viewModel.user?.avatarURL) { phase in
                        if let image = phase.image {
                            image.resizable().scaledToFill()
                        } else {
                            TalkoraAvatar(name: viewModel.user?.displayName ?? "?", size: 60)
                        }
                    }
                    .frame(width: 60, height: 60)
                    .clipShape(Circle())

                    VStack(alignment: .leading, spacing: 2) {
                        Text(viewModel.user?.displayName ?? "")
                            .font(Font.headline)
                            .foregroundStyle(Color.primary)
                        Text(viewModel.user?.handle ?? "")
                            .font(Font.caption)
                            .foregroundStyle(Color.secondary)
                        if let bio = viewModel.user?.bio, !bio.isEmpty {
                            Text(bio)
                                .font(Font.caption)
                                .foregroundStyle(Color.secondary)
                                .lineLimit(1)
                        }
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(Color.secondary)
                }
            }
        }
    }

    private var appearanceSection: some View {
        Section {
            Picker(
                "Appearance",
                selection: Binding(
                    get: { viewModel.theme },
                    set: { viewModel.setTheme($0) }
                )
            ) {
                Text("System").tag(TalkoraTheme.system)
                Text("Light").tag(TalkoraTheme.light)
                Text("Dark").tag(TalkoraTheme.dark)
            }
        } header: {
            Text("Appearance")
        }
    }
}

#if DEBUG
#Preview("Loaded") {
    ProfileScreen(viewModel: ProfileViewModel(previewScenario: .loaded))
}

#Preview("Loading") {
    ProfileScreen(viewModel: ProfileViewModel(previewScenario: .loading))
}

#Preview("Empty") {
    ProfileScreen(viewModel: ProfileViewModel(previewScenario: .empty))
}

#Preview("Error") {
    ProfileScreen(viewModel: ProfileViewModel(previewScenario: .failed))
}
#endif
