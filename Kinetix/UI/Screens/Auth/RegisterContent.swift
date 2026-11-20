import KinetixDomain
import KinetixPresentation
import SwiftUI

struct RegisterContent: View {
    @Binding var email: String
    @Binding var password: String
    let state: RegisterState
    let canSubmit: Bool
    let failureMapper: FailureMessageMapper
    let onSubmit: () -> Void

    @FocusState private var focusedField: AuthFormField?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: KinetixTheme.spacingLarge) {
                VStack(alignment: .leading, spacing: KinetixTheme.spacingXSmall) {
                    Text(.authRegisterTitle)
                        .font(KinetixTypography.display)
                        .foregroundStyle(KinetixPalette.textPrimary)

                    Text(.authRegisterPasswordHint)
                        .font(KinetixTypography.body)
                        .foregroundStyle(KinetixPalette.textSecondary)
                }
                .padding(.top, KinetixTheme.spacingSmall)

                statusSection

                VStack(spacing: KinetixTheme.spacingMedium) {
                    KinetixTextField(
                        label: .authEmailLabel,
                        placeholder: .authEmailPlaceholder,
                        text: $email,
                        isFocused: focusedField == .email,
                        keyboardType: .emailAddress,
                        contentType: .emailAddress,
                        submitLabel: .next,
                        onSubmit: {
                            focusedField = .password
                        },
                    )
                    .focused($focusedField, equals: .email)

                    KinetixTextField(
                        label: .authPasswordLabel,
                        placeholder: .authNewPasswordPlaceholder,
                        text: $password,
                        isSecure: true,
                        isFocused: focusedField == .password,
                        contentType: .newPassword,
                        submitLabel: .go,
                        onSubmit: {
                            focusedField = nil
                            onSubmit()
                        },
                    )
                    .focused($focusedField, equals: .password)

                    passwordRequirementsCard
                }

                KinetixPrimaryButton(
                    title: .authRegisterButton,
                    isLoading: state == .submitting,
                    isDisabled: !canSubmit,
                    action: {
                        focusedField = nil
                        onSubmit()
                    },
                )
            }
            .padding(.horizontal, KinetixTheme.spacingLarge)
            .padding(.bottom, KinetixTheme.spacingLarge)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(KinetixPalette.background.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
    }

    private var passwordRequirementsCard: some View {
        let meetsMin = password.count >= 12
        let withinMaxBytes = !password.isEmpty && password.utf8.count <= 72

        return VStack(alignment: .leading, spacing: KinetixTheme.spacingXSmall) {
            requirementRow(
                label: .authPasswordMinRule,
                satisfied: meetsMin,
            )

            requirementRow(
                label: .authPasswordMaxRule,
                satisfied: withinMaxBytes,
            )
        }
        .padding(KinetixTheme.spacingMedium)
        .frame(maxWidth: .infinity, alignment: .leading)
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

    private func requirementRow(
        label: LocalizedStringResource,
        satisfied: Bool,
    ) -> some View {
        HStack(spacing: KinetixTheme.spacingSmall) {
            Image(systemName: satisfied ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(
                    satisfied ? KinetixPalette.successGreen : KinetixPalette.textMuted
                )
                .accessibilityHidden(true)

            Text(label)
                .font(KinetixTypography.fieldLabel)
                .foregroundStyle(
                    satisfied ? KinetixPalette.textPrimary : KinetixPalette.textTertiary
                )
        }
    }

    @ViewBuilder
    private var statusSection: some View {
        switch state {
        case .idle, .submitting, .registered:
            EmptyView()
        case .rateLimited(let seconds):
            KinetixStatusBanner(
                tone: .warning,
                message: .authRateLimitCountdown(seconds),
            )
        case .failed(.conflict):
            KinetixStatusBanner(
                tone: .danger,
                message: .authEmailAlreadyRegistered,
            )
        case .failed(let failure):
            KinetixStatusBanner(
                tone: .danger,
                message: failureMapper.message(for: failure),
            )
        }
    }
}

#Preview {
    RegisterContent(
        email: .constant(""),
        password: .constant(""),
        state: .idle,
        canSubmit: false,
        failureMapper: FailureMessageMapper(),
        onSubmit: {},
    )
    .preferredColorScheme(.dark)
}
