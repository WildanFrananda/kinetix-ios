import SwiftUI

struct KinetixBrandHeader: View {
    private let tileSize: CGFloat = 38

    var body: some View {
        HStack(spacing: KinetixTheme.spacingSmall) {
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 6)
                    .fill(KinetixPalette.textPrimary)

                KinetixLogoMark()
                    .stroke(
                        KinetixPalette.background,
                        style: StrokeStyle(
                            lineWidth: tileSize * (2.6 / 32.0),
                            lineCap: .square,
                        ),
                    )

                Circle()
                    .fill(KinetixPalette.accent)
                    .frame(
                        width: tileSize * (6.8 / 32.0),
                        height: tileSize * (6.8 / 32.0),
                    )
                    .offset(
                        x: tileSize * (6.6 / 32.0),
                        y: tileSize * (12.6 / 32.0),
                    )
            }
            .frame(width: tileSize, height: tileSize)
            .accessibilityHidden(true)

            Text(.brandNameUppercase)
                .font(.system(.title3, design: .default, weight: .bold))
                .tracking(3.2)
                .foregroundStyle(KinetixPalette.textPrimary)
        }
        .accessibilityElement(children: .combine)
    }
}
