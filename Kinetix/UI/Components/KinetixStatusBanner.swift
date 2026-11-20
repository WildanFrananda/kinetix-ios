import SwiftUI

struct KinetixStatusBanner: View {
    let tone: StatusBannerTone
    let message: LocalizedStringResource

    var body: some View {
        HStack(alignment: .center, spacing: KinetixTheme.spacingSmall) {
            Image(systemName: tone.systemImage)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(tone.foregroundColor)
                .accessibilityHidden(true)

            Text(message)
                .font(KinetixTypography.subheadline)
                .foregroundStyle(KinetixPalette.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)
        }
        .padding(KinetixTheme.spacingMedium)
        .background(KinetixPalette.surfaceElevated)
        .clipShape(RoundedRectangle(cornerRadius: KinetixTheme.cornerRadiusCard))
        .overlay(
            RoundedRectangle(cornerRadius: KinetixTheme.cornerRadiusCard)
                .stroke(
                    tone == .info ? KinetixPalette.borderStrong : tone.foregroundColor,
                    lineWidth: KinetixTheme.borderWidthHairline,
                )
        )
        .accessibilityElement(children: .combine)
    }
}
