import KinetixDomain
import SwiftUI

struct LanguageSettingsContent: View {
    let selectedLanguage: AppLanguage
    let onSelectLanguage: (AppLanguage) -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: KinetixTheme.spacingLarge) {
                VStack(alignment: .leading, spacing: KinetixTheme.spacingXSmall) {
                    Text(.languageSettingsTitle)
                        .font(KinetixTypography.display)
                        .foregroundStyle(KinetixPalette.textPrimary)

                    Text(.languageSettingsSubtitle)
                        .font(KinetixTypography.body)
                        .foregroundStyle(KinetixPalette.textSecondary)
                }

                VStack(alignment: .leading, spacing: KinetixTheme.spacingSmall) {
                    KinetixSectionHeader(title: .languageSettingsSectionLabel)

                    VStack(spacing: 0) {
                        ForEach(
                            Array(AppLanguage.allCases.enumerated()),
                            id: \.element,
                        ) { offset, option in
                            if offset > 0 {
                                Rectangle()
                                    .fill(KinetixPalette.borderHairline)
                                    .frame(height: KinetixTheme.borderWidthHairline)
                                    .padding(.leading, KinetixTheme.spacingMedium)
                            }

                            optionRow(option: option)
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
                }
            }
            .padding(.horizontal, KinetixTheme.spacingMedium)
            .padding(.vertical, KinetixTheme.spacingMedium)
        }
        .background(KinetixPalette.background.ignoresSafeArea())
        .navigationTitle(Text(.languageSettingsTitle))
        .navigationBarTitleDisplayMode(.inline)
    }

    private func optionRow(option: AppLanguage) -> some View {
        let isSelected = selectedLanguage == option

        return Button {
            onSelectLanguage(option)
        } label: {
            HStack(spacing: KinetixTheme.spacingMedium) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(optionTitle(for: option))
                        .font(KinetixTypography.title)
                        .foregroundStyle(
                            isSelected ? KinetixPalette.accentHigh : KinetixPalette.textPrimary
                        )

                    Text(optionSubtitle(for: option))
                        .font(KinetixTypography.fieldLabel)
                        .foregroundStyle(KinetixPalette.textSecondary)
                }

                Spacer(minLength: 0)

                Image(
                    systemName: isSelected ? "checkmark.circle.fill" : "circle"
                )
                .font(.system(size: 19, weight: .semibold))
                .foregroundStyle(
                    isSelected ? KinetixPalette.accent : KinetixPalette.textMuted
                )
                .accessibilityHidden(true)
            }
            .padding(.horizontal, KinetixTheme.spacingMedium)
            .padding(.vertical, 14)
            .frame(minHeight: 60)
            .background(
                isSelected ? KinetixPalette.accentLow.opacity(0.45) : Color.clear
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func optionTitle(for option: AppLanguage) -> LocalizedStringResource {
        switch option {
        case .system:
            return .languageOptionSystemTitle
        case .english:
            return .languageOptionEnglishTitle
        case .indonesian:
            return .languageOptionIndonesianTitle
        }
    }

    private func optionSubtitle(for option: AppLanguage) -> LocalizedStringResource {
        switch option {
        case .system:
            return .languageOptionSystemSubtitle
        case .english:
            return .languageOptionEnglishSubtitle
        case .indonesian:
            return .languageOptionIndonesianSubtitle
        }
    }
}

#Preview {
    NavigationStack {
        LanguageSettingsContent(
            selectedLanguage: .system,
            onSelectLanguage: { _ in },
        )
    }
    .preferredColorScheme(.dark)
}
