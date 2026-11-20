import SwiftUI
import UIKit

struct KinetixRemoteImage: View {
    let url: URL?
    let maxPixelDimension: Int
    let pipeline: ImagePipeline?

    @State private var loadedImage: UIImage?

    init(
        url: URL?,
        maxPixelDimension: Int = 360,
        pipeline: ImagePipeline? = nil,
    ) {
        self.url = url
        self.maxPixelDimension = maxPixelDimension
        self.pipeline = pipeline
    }

    var body: some View {
        ZStack {
            KinetixPalette.surfaceElevated

            if let loadedImage {
                Image(uiImage: loadedImage)
                    .resizable()
                    .scaledToFill()
            } else {
                Image(systemName: "shippingbox")
                    .font(.system(size: 20, weight: .regular))
                    .foregroundStyle(KinetixPalette.textMuted)
            }
        }
        .clipped()
        .task(id: url) {
            loadedImage = nil
            guard let url, let pipeline else {
                return
            }

            let image = await pipeline.image(
                for: url,
                maxPixelDimension: maxPixelDimension,
            )
            if !Task.isCancelled {
                loadedImage = image
            }
        }
        .accessibilityHidden(true)
    }
}
