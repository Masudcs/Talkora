import CoreImage.CIFilterBuiltins
import UIKit
import Core

/// Generates a scannable QR code entirely on-device — no backend call needed since the
/// payload is just the current user's id.
enum QRCodeGenerator {
    static func image(for string: String) -> UIImage? {
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(string.utf8)
        guard let outputImage = filter.outputImage else { return nil }
        let scaled = outputImage.transformed(by: CGAffineTransform(scaleX: 10, y: 10))
        guard let cgImage = context.createCGImage(scaled, from: scaled.extent) else { return nil }
        return UIImage(cgImage: cgImage)
    }
}
