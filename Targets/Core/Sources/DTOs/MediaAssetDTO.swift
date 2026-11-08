import Foundation

/// Wire-format representation of a pickable item in the mock "camera roll / files" catalog.
public struct MediaAssetDTO: Codable, Sendable, Hashable {
    public let id: String
    public let kind: String
    public let fileName: String
    public let thumbnailURL: String?
    public let originalSizeBytes: Int
    public let durationSeconds: Double?

    public init(id: String, kind: String, fileName: String, thumbnailURL: String?, originalSizeBytes: Int, durationSeconds: Double? = nil) {
        self.id = id
        self.kind = kind
        self.fileName = fileName
        self.thumbnailURL = thumbnailURL
        self.originalSizeBytes = originalSizeBytes
        self.durationSeconds = durationSeconds
    }
}
