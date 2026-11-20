import SwiftUI

struct KinetixSectionHeader: View {
    let title: LocalizedStringResource

    var body: some View {
        Text(title)
            .font(KinetixTypography.eyebrow)
            .tracking(0.8)
            .foregroundStyle(KinetixPalette.textTertiary)
            .textCase(.uppercase)
            .padding(.horizontal, 2)
    }
}
