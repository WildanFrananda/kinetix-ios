import KinetixDomain
import SwiftUI

struct ConfigErrorContent: View {
    let issues: [AppConfigIssue]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: KinetixTheme.spacingLarge) {
                HStack(spacing: KinetixTheme.spacingSmall) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(KinetixPalette.dangerCoral)
                        .accessibilityHidden(true)

                    Text(.configErrorTitle)
                        .font(KinetixTypography.headline)
                        .foregroundStyle(KinetixPalette.textPrimary)
                }

                Text(.configErrorSubtitle)
                    .font(KinetixTypography.body)
                    .foregroundStyle(KinetixPalette.textSecondary)

                VStack(alignment: .leading, spacing: KinetixTheme.spacingSmall) {
                    ForEach(issues, id: \.self) { issue in
                        HStack(alignment: .firstTextBaseline, spacing: KinetixTheme.spacingMedium) {
                            Text(issue.key.rawValue)
                                .font(KinetixTypography.labelMono)
                                .foregroundStyle(KinetixPalette.textPrimary)
                                .fixedSize(horizontal: false, vertical: true)

                            Spacer(minLength: KinetixTheme.spacingSmall)

                            Text(label(for: issue.kind))
                                .font(KinetixTypography.labelMono)
                                .foregroundStyle(KinetixPalette.dangerCoral)
                                .padding(.horizontal, KinetixTheme.spacingSmall)
                                .padding(.vertical, KinetixTheme.spacingXSmall)
                                .background(KinetixPalette.cardSlate)
                                .clipShape(
                                    RoundedRectangle(cornerRadius: KinetixTheme.cornerRadiusBadge)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: KinetixTheme.cornerRadiusBadge)
                                        .stroke(
                                            KinetixPalette.borderHairline,
                                            lineWidth: KinetixTheme.borderWidthHairline,
                                        )
                                )
                        }
                        .padding(KinetixTheme.spacingMedium)
                        .background(KinetixPalette.elevatedSlate)
                        .clipShape(RoundedRectangle(cornerRadius: KinetixTheme.cornerRadiusCard))
                        .overlay(
                            RoundedRectangle(cornerRadius: KinetixTheme.cornerRadiusCard)
                                .stroke(
                                    KinetixPalette.borderHairline,
                                    lineWidth: KinetixTheme.borderWidthHairline,
                                )
                        )
                        .accessibilityElement(children: .combine)
                    }
                }

                Text(.configErrorFooter)
                    .font(KinetixTypography.body)
                    .foregroundStyle(KinetixPalette.textSecondary)
            }
            .padding(KinetixTheme.spacingLarge)
        }
        .background(KinetixPalette.obsidianSurface.ignoresSafeArea())
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
