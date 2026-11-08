import SwiftUI
import Core
import Mock

/// Presented from `ChatSettingsSheet`. Improve (WhatsApp-style, without needing real image
/// upload): a per-chat wallpaper picked from a fixed gradient palette.
struct ChatWallpaperPickerScreen: View {
    @State private var viewModel: ChatWallpaperPickerViewModel
    @Environment(\.dismiss) private var dismiss

    init(conversationId: String, selected: ChatWallpaper, onChanged: @escaping (Conversation) -> Void) {
        _viewModel = State(wrappedValue: ChatWallpaperPickerViewModel(
            conversationId: conversationId,
            selected: selected,
            onChanged: onChanged
        ))
    }

    init(viewModel: ChatWallpaperPickerViewModel) {
        _viewModel = State(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            List(ChatWallpaper.allCases, id: \.self) { wallpaper in
                Button {
                    Task { await viewModel.select(wallpaper) }
                } label: {
                    HStack {
                        wallpaper.background
                            .frame(width: 44, height: 44)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(Color(.separator), lineWidth: 1))
                        Text(wallpaper.displayName)
                            .foregroundStyle(Color.primary)
                        Spacer()
                        if viewModel.selected == wallpaper {
                            Image(systemName: "checkmark")
                                .foregroundStyle(Color.accentColor)
                        }
                    }
                }
            }
            .navigationTitle("Chat Wallpaper")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

#if DEBUG
#Preview("Default Selected") {
    ChatWallpaperPickerScreen(viewModel: ChatWallpaperPickerViewModel(conversationId: PreviewData.directConversation.id, selected: .default, onChanged: { _ in }))
}

#Preview("Ocean Selected") {
    ChatWallpaperPickerScreen(viewModel: ChatWallpaperPickerViewModel(conversationId: PreviewData.directConversation.id, selected: .ocean, onChanged: { _ in }))
}
#endif
