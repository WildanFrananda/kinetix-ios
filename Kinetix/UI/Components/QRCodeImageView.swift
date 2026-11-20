import CoreImage.CIFilterBuiltins
import SwiftUI

struct QRCodeImageView: View {
    let payload: String

    var body: some View {
        if let image = generateQRCode(from: payload) {
            Image(uiImage: image)
                .interpolation(.none)
                .resizable()
                .scaledToFit()
                .frame(width: 200, height: 200)
                .padding(KinetixTheme.spacingMedium)
                .background(KinetixPalette.tileLight)
                .clipShape(RoundedRectangle(cornerRadius: KinetixTheme.cornerRadiusControl))
                .accessibilityLabel(Text(.twoFactorQrCodeAccessibility))
        }
    }

    private func generateQRCode(from text: String) -> UIImage? {
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(text.utf8)
        filter.correctionLevel = "M"

        guard let outputImage = filter.outputImage else {
            return nil
        }

        let context = CIContext()
        let scaled = outputImage.transformed(by: CGAffineTransform(scaleX: 8, y: 8))
        guard let cgImage = context.createCGImage(scaled, from: scaled.extent) else {
            return nil
        }

        return UIImage(cgImage: cgImage)
    }
}
