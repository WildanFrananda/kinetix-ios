import SwiftUI

struct AccountHomeContent: View {
    let email: String
    let isSigningOut: Bool
    let onOpenProfile: () -> Void
    let onOpenTwoFactor: () -> Void
    let onSignOut: () -> Void

    @State private var showingSignOutConfirmation = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: KinetixTheme.spacingLarge) {
                KinetixBrandHeader()
                    .padding(.top, KinetixTheme.spacingSmall)

                accountCard

                VStack(alignment: .leading, spacing: KinetixTheme.spacingSmall) {
                    KinetixSectionHeader(title: .accountSectionSettings)

                    VStack(spacing: 0) {
                        navigationRow(
                            title: .profileTitle,
                            subtitle: .accountProfileRowSubtitle,
                            icon: "person.text.rectangle",
                            action: onOpenProfile,
                        )

                        Rectangle()
                            .fill(KinetixPalette.borderHairline)
                            .frame(height: KinetixTheme.borderWidthHairline)
                            .padding(.leading, 56)

                        navigationRow(
                            title: .twoFactorSettingsTitle,
                            subtitle: .accountTwoFactorRowSubtitle,
                            icon: "lock.shield",
                            action: onOpenTwoFactor,
                        )
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

                VStack(alignment: .leading, spacing: KinetixTheme.spacingSmall) {
                    KinetixSectionHeader(title: .accountSectionSession)

                    Button {
                        showingSignOutConfirmation = true
                    } label: {
                        HStack(spacing: KinetixTheme.spacingMedium) {
                            if isSigningOut {
                                ProgressView()
                                    .tint(KinetixPalette.dangerRed)
                            } else {
                                Image(systemName: "rectangle.portrait.and.arrow.right")
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundStyle(KinetixPalette.dangerRed)
                                    .frame(width: 24)
                                    .accessibilityHidden(true)
                            }

                            Text(.authSignOutButton)
                                .font(KinetixTypography.title)
                                .foregroundStyle(KinetixPalette.dangerRed)

                            Spacer()
                        }
                        .padding(.horizontal, KinetixTheme.spacingMedium)
                        .frame(maxWidth: .infinity, minHeight: KinetixTheme.controlHeight)
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
                    .buttonStyle(.plain)
                    .disabled(isSigningOut)
                }
            }
            .padding(.horizontal, KinetixTheme.spacingMedium)
            .padding(.bottom, KinetixTheme.spacingLarge)
        }
        .background(KinetixPalette.background.ignoresSafeArea())
        .confirmationDialog(
            Text(.authSignOutConfirmTitle),
            isPresented: $showingSignOutConfirmation,
            titleVisibility: .visible,
        ) {
            Button(role: .destructive, action: onSignOut) {
                Text(.authSignOutButton)
            }

            Button(role: .cancel) {
            } label: {
                Text(.commonCancelButton)
            }
        } message: {
            Text(.authSignOutConfirmMessage)
        }
    }

    private var accountCard: some View {
        HStack(spacing: KinetixTheme.spacingMedium) {
            ZStack {
                RoundedRectangle(cornerRadius: KinetixTheme.cornerRadiusControl)
                    .fill(KinetixPalette.accentLow)
                    .overlay(
                        RoundedRectangle(cornerRadius: KinetixTheme.cornerRadiusControl)
                            .stroke(
                                KinetixPalette.accent.opacity(0.45),
                                lineWidth: KinetixTheme.borderWidthHairline,
                            )
                    )

                Text(initialLetter)
                    .font(KinetixTypography.title)
                    .foregroundStyle(KinetixPalette.accentHigh)
            }
            .frame(width: 48, height: 48)
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(.accountTitle)
                    .font(KinetixTypography.title)
                    .foregroundStyle(KinetixPalette.textPrimary)

                Text(email)
                    .font(KinetixTypography.subheadline)
                    .foregroundStyle(KinetixPalette.textTertiary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }

            Spacer(minLength: 0)
        }
        .padding(KinetixTheme.spacingMedium)
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

    private var initialLetter: String {
        guard let first = email.trimmingCharacters(in: .whitespacesAndNewlines).first else {
            return "K"
        }

        return String(first).uppercased()
    }

    private func navigationRow(
        title: LocalizedStringResource,
        subtitle: LocalizedStringResource,
        icon: String,
        action: @escaping () -> Void,
    ) -> some View {
        Button(action: action) {
            HStack(spacing: KinetixTheme.spacingMedium) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(KinetixPalette.textPrimary)
                    .frame(width: 24)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(KinetixTypography.title)
                        .foregroundStyle(KinetixPalette.textPrimary)

                    Text(subtitle)
                        .font(KinetixTypography.fieldLabel)
                        .foregroundStyle(KinetixPalette.textSecondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(KinetixPalette.textMuted)
                    .accessibilityHidden(true)
            }
            .padding(.horizontal, KinetixTheme.spacingMedium)
            .padding(.vertical, 14)
            .frame(minHeight: 60)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    AccountHomeContent(
        email: "",
        isSigningOut: false,
        onOpenProfile: {},
        onOpenTwoFactor: {},
        onSignOut: {},
    )
    .preferredColorScheme(.dark)
}
