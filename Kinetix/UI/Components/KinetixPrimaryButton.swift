import SwiftUI

struct KinetixPrimaryButton: View {
    let title: LocalizedStringResource
    let isLoading: Bool
    let isDisabled: Bool
    let action: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(
        title: LocalizedStringResource,
        isLoading: Bool = false,
        isDisabled: Bool = false,
        action: @escaping () -> Void,
    ) {
        self.title = title
        self.isLoading = isLoading
        self.isDisabled = isDisabled
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: KinetixTheme.spacingSmall) {
                if isLoading {
                    ProgressView()
                        .tint(KinetixPalette.background)
                }

                Text(title)
                    .font(KinetixTypography.title)
                    .foregroundStyle(
                        isDisabled
                            ? KinetixPalette.accentHigh.opacity(0.85)
                            : KinetixPalette.background
                    )
            }
            .frame(maxWidth: .infinity, minHeight: KinetixTheme.controlHeight)
            .background(isDisabled ? KinetixPalette.accentLow : KinetixPalette.accent)
            .clipShape(RoundedRectangle(cornerRadius: KinetixTheme.cornerRadiusControl))
            .overlay(
                RoundedRectangle(cornerRadius: KinetixTheme.cornerRadiusControl)
                    .stroke(
                        isDisabled ? KinetixPalette.accent.opacity(0.35) : Color.clear,
                        lineWidth: KinetixTheme.borderWidthHairline,
                    )
            )
        }
        .buttonStyle(KinetixPressButtonStyle(reduceMotion: reduceMotion))
        .disabled(isDisabled || isLoading)
    }
}
