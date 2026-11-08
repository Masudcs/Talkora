import SwiftUI
import Core

/// Full-screen viewer shown when a view-once attachment is tapped. The attachment is
/// already marked consumed server-side by `ChatThreadViewModel.revealViewOnce` the moment
/// this appears — dismissing just closes the viewer, it doesn't undo the consumption.
struct ViewOnceMediaViewer: View {
    let attachment: MediaAttachment
    let onClose: () -> Void

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color.black.ignoresSafeArea()

            switch attachment.kind {
            case .image, .video:
                AsyncImage(url: attachment.url) { phase in
                    if let image = phase.image {
                        image.resizable().scaledToFit()
                    } else {
                        ProgressView().tint(.white)
                    }
                }
                .padding()
            case .file:
                Text(attachment.fileName)
                    .foregroundStyle(.white)
            }

            Button(action: onClose) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(.white)
                    .padding()
            }
        }
    }
}
