import Foundation

/// The mock "camera roll / files" catalog every conversation's media picker offers.
public enum MediaAssetFixtures {
    public static let seed: [MediaAssetDTO] = [
        MediaAssetDTO(id: "asset1", kind: "image", fileName: "IMG_0142.jpg", thumbnailURL: "https://picsum.photos/seed/asset1/800", originalSizeBytes: 4_200_000),
        MediaAssetDTO(id: "asset2", kind: "image", fileName: "IMG_0158.jpg", thumbnailURL: "https://picsum.photos/seed/asset2/800", originalSizeBytes: 3_100_000),
        MediaAssetDTO(id: "asset3", kind: "image", fileName: "IMG_0201.jpg", thumbnailURL: "https://picsum.photos/seed/asset3/800", originalSizeBytes: 5_600_000),
        MediaAssetDTO(id: "asset4", kind: "image", fileName: "Screenshot.png", thumbnailURL: "https://picsum.photos/seed/asset4/800", originalSizeBytes: 1_800_000),
        MediaAssetDTO(id: "asset5", kind: "video", fileName: "IMG_0177.mov", thumbnailURL: "https://picsum.photos/seed/asset5/800", originalSizeBytes: 42_000_000, durationSeconds: 18),
        MediaAssetDTO(id: "asset6", kind: "video", fileName: "IMG_0189.mov", thumbnailURL: "https://picsum.photos/seed/asset6/800", originalSizeBytes: 88_000_000, durationSeconds: 41),
        MediaAssetDTO(id: "asset7", kind: "file", fileName: "Itinerary.pdf", thumbnailURL: nil, originalSizeBytes: 640_000),
        MediaAssetDTO(id: "asset8", kind: "file", fileName: "Budget.xlsx", thumbnailURL: nil, originalSizeBytes: 210_000),
        MediaAssetDTO(id: "asset9", kind: "file", fileName: "Contract.docx", thumbnailURL: nil, originalSizeBytes: 95_000),
    ]
}
