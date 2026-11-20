import KinetixDomain
import SwiftUI

struct ConfigErrorContent: View {
    let issues: [AppConfigIssue]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: KinetixTheme.spacingLarge) {
                KinetixBrandHeader()
                    .padding(.top, KinetixTheme.spacingMedium)

                HStack(spacing: KinetixTheme.spacingSmall) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(KinetixPalette.dangerRed)
                        .accessibilityHidden(true)

                    Text(.configErrorTitle)
                        .font(KinetixTypography.headline)
                        .foregroundStyle(KinetixPalette.textPrimary)
                }

                Text(.configErrorSubtitle)
                    .font(KinetixTypography.body)
                    .foregroundStyle(KinetixPalette.textSecondary)

                VStack(spacing: 0) {
                    ForEach(Array(issues.enumerated()), id: \.element) { offset, issue in
                        if offset > 0 {
                            Rectangle()
                                .fill(KinetixPalette.borderHairline)
                                .frame(height: KinetixTheme.borderWidthHairline)
                                .padding(.leading, KinetixTheme.spacingMedium)
                        }

                        HStack(alignment: .center, spacing: KinetixTheme.spacingMedium) {
                            Text(issue.key.rawValue)
                                .font(KinetixTypography.labelMono)
                                .foregroundStyle(KinetixPalette.textPrimary)
                                .fixedSize(horizontal: false, vertical: true)

                            Spacer(minLength: KinetixTheme.spacingSmall)

                            Text(label(for: issue.kind))
                                .font(KinetixTypography.fieldLabel)
                                .foregroundStyle(KinetixPalette.dangerRed)
                                .padding(.horizontal, KinetixTheme.spacingSmall)
                                .padding(.vertical, 4)
                                .background(KinetixPalette.surfaceElevated)
                                .clipShape(
                                    RoundedRectangle(cornerRadius: KinetixTheme.cornerRadiusControl)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: KinetixTheme.cornerRadiusControl)
                                        .stroke(
                                            KinetixPalette.dangerRed,
                                            lineWidth: KinetixTheme.borderWidthHairline,
                                        )
                                )
                        }
                        .padding(KinetixTheme.spacingMedium)
                        .accessibilityElement(children: .combine)
                    }
                }
                .background(KinetixPalette.surface)
                .clipShape(RoundedRectangle(cornerRadius: KinetixTheme.cornerRadiusCard))
                .overlay(
                    RoundedRectangle(cornerRadius: KinetixTheme.cornerRadiusCard)
                        .stroke(
                            KinetixPalette.borderHairline,
                            lineWidth: KinetixTheme.borderWidthHairline,
                        )
                )

                Text(.configErrorFooter)
                    .font(KinetixTypography.subheadline)
                    .foregroundStyle(KinetixPalette.textTertiary)
            }
            .padding(KinetixTheme.spacingLarge)
        }
        .background(KinetixPalette.background.ignoresSafeArea())
    }

    private func label(for kind: AppConfigIssueKind) -> LocalizedStringResource {
        switch kind {
        case .missing:
            return .configErrorIssueMissing
        case .malformed:
            return .configErrorIssueMalformed
        }
    }
}

#Preview {
    ConfigErrorContent(
        issues: [
            AppConfigIssue(key: .httpBase, kind: .missing),
            AppConfigIssue(key: .wsBase, kind: .malformed),
        ]
    )
    .preferredColorScheme(.dark)
}
