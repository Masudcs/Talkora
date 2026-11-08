import Foundation

public enum MediaKind: String, Sendable {
    case image
    case video
    case file
}

/// `compressed` attachments are smaller than the original; files are never compressed.
public enum MediaQuality: String, Sendable {
    case original
    case compressed
}

/// A sent/persisted attachment on a message.
public struct MediaAttachment: Identifiable, Hashable, Sendable {
    public let id: String
    public let kind: MediaKind
    public let fileName: String
    public let sizeBytes: Int
    public let quality: MediaQuality
    public let url: URL?
    public let durationSeconds: TimeInterval?
    /// Uncommon (WhatsApp): once opened, the media can't be viewed again — by anyone,
    /// including the sender, matching real view-once semantics.
    public let isViewOnce: Bool
    public let isConsumed: Bool

    public init(
        id: String,
        kind: MediaKind,
        fileName: String,
        sizeBytes: Int,
        quality: MediaQuality,
        url: URL?,
        durationSeconds: TimeInterval?,
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
}

/// A pickable item from the mock "photo library / files" catalog, before it's sent.
public struct MediaAsset: Identifiable, Hashable, Sendable {
    public let id: String
    public let kind: MediaKind
    public let fileName: String
    public let thumbnailURL: URL?
    public let originalSizeBytes: Int
    public let durationSeconds: TimeInterval?

    public init(id: String, kind: MediaKind, fileName: String, thumbnailURL: URL?, originalSizeBytes: Int, durationSeconds: TimeInterval?) {
        self.id = id
        self.kind = kind
        self.fileName = fileName
        self.thumbnailURL = thumbnailURL
        self.originalSizeBytes = originalSizeBytes
        self.durationSeconds = durationSeconds
    }
}
