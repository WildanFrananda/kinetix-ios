import KinetixDomain
import KinetixPresentation
import SwiftUI

struct SignInContent: View {
    @Binding var email: String
    @Binding var password: String
    let state: SignInState
    let canSubmit: Bool
    let failureMapper: FailureMessageMapper
    let onSubmit: () -> Void
    let onNavigateRegister: () -> Void

    @FocusState private var focusedField: AuthFormField?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: KinetixTheme.spacingXLarge) {
                KinetixBrandHeader()
                    .padding(.top, KinetixTheme.spacingMedium)

                VStack(alignment: .leading, spacing: KinetixTheme.spacingXSmall) {
                    Text(.authSignInTitle)
                        .font(KinetixTypography.display)
                        .foregroundStyle(KinetixPalette.textPrimary)

                    Text(.authSignInSubtitle)
                        .font(KinetixTypography.body)
                        .foregroundStyle(KinetixPalette.textSecondary)
                }

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
                        placeholder: .authPasswordPlaceholder,
                        text: $password,
                        isSecure: true,
                        isFocused: focusedField == .password,
                        contentType: .password,
                        submitLabel: .go,
                        onSubmit: {
                            focusedField = nil
                            onSubmit()
                        },
                    )
                    .focused($focusedField, equals: .password)
                }

                KinetixPrimaryButton(
                    title: .authSignInButton,
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
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 0) {
                Rectangle()
                    .fill(KinetixPalette.borderHairline)
                    .frame(height: KinetixTheme.borderWidthHairline)

                HStack(spacing: 6) {
                    Text(.authNewToKinetixPrompt)
                        .font(KinetixTypography.subheadline)
                        .foregroundStyle(KinetixPalette.textTertiary)

                    Button(action: onNavigateRegister) {
                        Text(.authCreateAccountAction)
                            .font(KinetixTypography.title)
                            .foregroundStyle(KinetixPalette.textPrimary)
                            .underline(true, color: KinetixPalette.accent)
                            .frame(minHeight: KinetixTheme.minTapTarget)
                    }
                    .buttonStyle(.plain)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, KinetixTheme.spacingXSmall)
                .background(KinetixPalette.background)
            }
        }
    }

    @ViewBuilder
    private var statusSection: some View {
        switch state {
        case .idle, .submitting, .signedIn, .twoFactorRequired:
            EmptyView()
        case .rateLimited(let seconds, let isSignInDelayed):
            KinetixStatusBanner(
                tone: .warning,
                message: isSignInDelayed
                    ? .authSignInDelayedCountdown(seconds)
                    : .authRateLimitCountdown(seconds),
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
    SignInContent(
        email: .constant(""),
        password: .constant(""),
        state: .idle,
        canSubmit: false,
        failureMapper: FailureMessageMapper(),
        onSubmit: {},
        onNavigateRegister: {},
    )
    .preferredColorScheme(.dark)
}
