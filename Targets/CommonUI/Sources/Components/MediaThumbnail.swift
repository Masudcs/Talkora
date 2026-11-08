import SwiftUI
import Core

/// Square thumbnail used both in the picker grid and the "Media & Files" history grid.
public struct MediaThumbnail: View {
    public let kind: MediaKind
    public let thumbnailURL: URL?
    public let durationSeconds: TimeInterval?
    public let fileName: String
    public var size: CGFloat = 100

    public var body: some View {
        ZStack(alignment: .bottomTrailing) {
            switch kind {
            case .image:
                AsyncImage(url: thumbnailURL) { phase in
                    if let image = phase.image {
                        image.resizable().scaledToFill()
                    } else {
                        Color(.secondarySystemBackground)
                    }
                }
                .frame(width: size, height: size)
                .clipped()
            case .video:
                ZStack {
                    AsyncImage(url: thumbnailURL) { phase in
                        if let image = phase.image {
                            image.resizable().scaledToFill()
                        } else {
                            Color(.secondarySystemBackground)
                        }
                    }
                    Image(systemName: "play.circle.fill")
                        .font(.system(size: size * 0.3))
                        .foregroundStyle(.white)
                }
                .frame(width: size, height: size)
                .clipped()
            case .file:
                VStack(spacing: 4) {
                    Image(systemName: "doc.fill")
                        .font(.system(size: size * 0.3))
                        .foregroundStyle(Color.accentColor)
                    Text(fileName)
                        .font(.caption2)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(Color.secondary)
                        .padding(.horizontal, 4)
                }
                .frame(width: size, height: size)
                .background(Color(.secondarySystemBackground))
            }

            if kind == .video, let durationSeconds {
                Text(Self.formattedDuration(durationSeconds))
                    .font(.caption2)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 2)
                    .background(.black.opacity(0.6))
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                    .padding(4)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    /// Formats seconds as `m:ss`, e.g. 18 becomes `0:18`; minutes are not wrapped into hours.
    public static func formattedDuration(_ duration: TimeInterval) -> String {
        let total = Int(duration)
        return String(format: "%d:%02d", total / 60, total % 60)
    }

    public init(kind: MediaKind, thumbnailURL: URL?, durationSeconds: TimeInterval?, fileName: String, size: CGFloat = 100) {
        self.kind = kind
        self.thumbnailURL = thumbnailURL
        self.durationSeconds = durationSeconds
        self.fileName = fileName
        self.size = size
    }
}
