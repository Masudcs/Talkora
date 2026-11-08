import SwiftUI
import Core
import CommonUI
import Mock

/// Edit sheet for display name, bio and avatar, presented from `ProfileScreen`. `onSaved` receives the updated user before the sheet dismisses; the sheet has its own `NavigationStack`.
struct EditProfileScreen: View {
    let onSaved: (User) -> Void
    @State private var viewModel: EditProfileViewModel
    @Environment(\.dismiss) private var dismiss

    init(user: User, onSaved: @escaping (User) -> Void, viewModel: EditProfileViewModel? = nil) {
        self.onSaved = onSaved
        _viewModel = State(wrappedValue: viewModel ?? EditProfileViewModel(user: user))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Spacer()
                        AsyncImage(url: viewModel.selectedAvatarURL) { phase in
                            if let image = phase.image {
                                image.resizable().scaledToFill()
                            } else {
                                TalkoraAvatar(name: viewModel.displayName.isEmpty ? "?" : viewModel.displayName, size: 88)
                            }
                        }
                        .frame(width: 88, height: 88)
                        .clipShape(Circle())
                        Spacer()
                    }
                    .listRowBackground(Color.clear)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(viewModel.avatarChoices) { asset in
                                Button {
                                    viewModel.selectAvatar(asset)
                                } label: {
                                    AsyncImage(url: asset.thumbnailURL) { phase in
                                        if let image = phase.image {
                                            image.resizable().scaledToFill()
                                        } else {
                                            Color(.secondarySystemBackground)
                                        }
                                    }
                                    .frame(width: 56, height: 56)
                                    .clipShape(Circle())
                                    .overlay(
                                        Circle().strokeBorder(
                                            viewModel.selectedAvatarURL == asset.thumbnailURL ? Color.accentColor : .clear,
                                            lineWidth: 3
                                        )
                                    )
                                }
                            }
                        }
                    }
                    .listRowBackground(Color.clear)
                } header: {
                    Text("Photo")
                }

                Section {
                    TextField("Your name", text: $viewModel.displayName)
                    TextField("Bio", text: $viewModel.bio, axis: .vertical)
                } header: {
                    Text("About")
                }

                if let error = viewModel.state.error {
                    Section {
                        Text(error.userMessage)
                            .foregroundStyle(Color.red)
                    }
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    if viewModel.state.isLoading {
                        ProgressView()
                    } else {
                        Button("Save") {
                            Task {
                                if let updated = await viewModel.save() {
                                    onSaved(updated)
                                    dismiss()
                                }
                            }
                        }
                        .disabled(!viewModel.canSubmit)
                    }
                }
            }
            .task { await viewModel.loadAvatarChoices() }
        }
    }
}

#if DEBUG
#Preview("Empty") {
    EditProfileScreen(user: PreviewData.currentUser, onSaved: { _ in }, viewModel: EditProfileViewModel(previewScenario: .empty))
}

#Preview("Invalid") {
    EditProfileScreen(user: PreviewData.currentUser, onSaved: { _ in }, viewModel: EditProfileViewModel(previewScenario: .invalid))
}

#Preview("Filled") {
    EditProfileScreen(user: PreviewData.currentUser, onSaved: { _ in }, viewModel: EditProfileViewModel(previewScenario: .filled))
}

#Preview("Submitting") {
    EditProfileScreen(user: PreviewData.currentUser, onSaved: { _ in }, viewModel: EditProfileViewModel(previewScenario: .submitting))
}

#Preview("Error") {
    EditProfileScreen(user: PreviewData.currentUser, onSaved: { _ in }, viewModel: EditProfileViewModel(previewScenario: .failed))
}
#endif
