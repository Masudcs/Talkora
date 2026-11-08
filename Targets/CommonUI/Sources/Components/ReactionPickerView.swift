import SwiftUI
import Core

/// Improve: the preset row is a convenience, not a ceiling — "Other…" opens a plain
/// text field backed by the system emoji keyboard, so the reaction set is genuinely
/// any emoji, never limited to a fixed palette or gated behind a paid tier.
public struct ReactionPickerView: View {
    public let onSelect: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var isCustomEntryPresented = false
    @State private var customEmoji = ""

    private static let presets = ["👍", "❤️", "😂", "😮", "😢", "🙏"]

    public var body: some View {
        VStack(spacing: 24) {
            HStack(spacing: 16) {
                ForEach(Self.presets, id: \.self) { emoji in
                    Button {
                        onSelect(emoji)
                        dismiss()
                    } label: {
                        Text(emoji).font(.system(size: 32))
                    }
                }
            }
            Button {
                isCustomEntryPresented = true
            } label: {
                Label("Other…", systemImage: "face.smiling")
            }
        }
        .padding(24)
        .presentationDetents([.height(160)])
        .alert("Add Reaction", isPresented: $isCustomEntryPresented) {
            TextField("Type any emoji", text: $customEmoji)
            Button("Add") {
                if let emoji = customEmoji.first.map(String.init) {
                    onSelect(emoji)
                }
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Tap the field and switch to your emoji keyboard.")
        }
    }

    public init(onSelect: @escaping (String) -> Void) {
        self.onSelect = onSelect
    }
}
