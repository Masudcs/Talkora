import Foundation

/// Unknown kinds fall back to `.file`; a malformed `thumbnailURL` becomes `nil`.
public extension MediaAssetDTO {
    func toDomain() -> MediaAsset {
        MediaAsset(
            id: id,
            kind: MediaKind(rawValue: kind) ?? .file,
            fileName: fileName,
            thumbnailURL: thumbnailURL.flatMap(URL.init(string:)),
            originalSizeBytes: originalSizeBytes,
            durationSeconds: durationSeconds
        )
    }
}
