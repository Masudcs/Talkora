import Foundation

/// Wire-format attachment on a message. `isViewOnce` / `isConsumed` carry the view-once state.
public struct MediaAttachmentDTO: Codable, Sendable, Hashable {
    public let id: String
    public let kind: String // "image" | "video" | "file"
    public let fileName: String
    public let sizeBytes: Int
    public let quality: String // "original" | "compressed"
    public let url: String?
    public let durationSeconds: Double?
    public let isViewOnce: Bool
    public let isConsumed: Bool

    public init(
        id: String,
        kind: String,
        fileName: String,
        sizeBytes: Int,
        quality: String,
        url: String?,
        durationSeconds: Double? = nil,
        isViewOnce: Bool = false,
        isConsumed: Bool = false
    ) {
        self.id = id
        self.kind = kind
        self.fileName = fileName
        self.sizeBytes = sizeBytes
        self.quality = quality
        self.url = url
        self.durationSeconds = durationSeconds
        self.isViewOnce = isViewOnce
        self.isConsumed = isConsumed
    }

    /// A copy with `isConsumed` set, leaving every other field as is.
    public func consumed() -> MediaAttachmentDTO {
        MediaAttachmentDTO(id: id, kind: kind, fileName: fileName, sizeBytes: sizeBytes, quality: quality, url: url, durationSeconds: durationSeconds, isViewOnce: isViewOnce, isConsumed: true)
    }
}
