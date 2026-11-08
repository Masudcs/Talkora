import SwiftUI
import Core
import CommonUI

/// Inline preview of an image, video (poster with play badge and duration) or file attachment.
struct MediaAttachmentView: View {
    let attachment: MediaAttachment

    var body: some View {
        switch attachment.kind {
        case .image:
            AsyncImage(url: attachment.url) { phase in
                if let image = phase.image {
                    image.resizable().scaledToFill()
                } else {
                    Color(.secondarySystemBackground)
                }
            }
            .frame(width: 200, height: 200)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        case .video:
            ZStack {
                AsyncImage(url: attachment.url) { phase in
                    if let image = phase.image {
                        image.resizable().scaledToFill()
                    } else {
                        Color.black
                    }
                }
                VStack(spacing: 4) {
                    Image(systemName: "play.circle.fill")
                        .font(.system(size: 36))
                        .foregroundStyle(.white)
                    if let duration = attachment.durationSeconds {
                        Text(MediaThumbnail.formattedDuration(duration))
                            .font(.caption)
                            .foregroundStyle(.white)
                    }
                }
            }
            .frame(width: 200, height: 200)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        case .file:
            HStack(spacing: 8) {
                Image(systemName: "doc.fill")
                    .font(.title2)
                    .foregroundStyle(Color.accentColor)
                VStack(alignment: .leading, spacing: 2) {
                    Text(attachment.fileName)
                        .lineLimit(1)
                        .font(Font.body)
                    Text(formattedSize(attachment.sizeBytes))
                        .font(.caption)
                        .foregroundStyle(Color.secondary)
                }
            }
            .padding(8)
            .frame(minWidth: 180, alignment: .leading)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private func formattedSize(_ bytes: Int) -> String {
        ByteCountFormatter.string(fromByteCount: Int64(bytes), countStyle: .file)
    }
}
