import KinetixDomain
import KinetixPresentation
import SwiftUI

struct TwoFactorChallengeContent: View {
    @Binding var code: String
    let state: TwoFactorChallengeState
    let canSubmit: Bool
    let failureMapper: FailureMessageMapper
    let onSubmit: () -> Void
    let onReturnToSignIn: () -> Void

    @FocusState private var isCodeFocused: Bool

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: KinetixTheme.spacingLarge) {
                HStack {
                    ZStack {
                        RoundedRectangle(cornerRadius: KinetixTheme.cornerRadiusControl)
                            .fill(KinetixPalette.surface)
                            .overlay(
                                RoundedRectangle(cornerRadius: KinetixTheme.cornerRadiusControl)
                                    .stroke(
                                        KinetixPalette.borderStrong,
                                        lineWidth: KinetixTheme.borderWidthHairline,
                                    )
                            )

                        Image(systemName: "lock.shield")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(KinetixPalette.accent)
                    }
                    .frame(width: 44, height: 44)
                    .accessibilityHidden(true)

                    Spacer()
                }
                .padding(.top, KinetixTheme.spacingSmall)

                VStack(alignment: .leading, spacing: KinetixTheme.spacingXSmall) {
                    Text(.twoFactorChallengeTitle)
                        .font(KinetixTypography.display)
                        .foregroundStyle(KinetixPalette.textPrimary)

                    Text(.twoFactorChallengeSubtitle)
                        .font(KinetixTypography.body)
                        .foregroundStyle(KinetixPalette.textSecondary)
                }

                statusSection

                VStack(alignment: .leading, spacing: KinetixTheme.spacingXSmall) {
                    Text(.twoFactorCodeLabel)
                        .font(KinetixTypography.fieldLabel)
                        .foregroundStyle(
                            isCodeFocused
                                ? KinetixPalette.textPrimary
                                : KinetixPalette.textSecondary
                        )

                    TextField(
                        "",
                        text: $code,
                        prompt: Text(.twoFactorCodePlaceholder)
                            .foregroundStyle(KinetixPalette.textTertiary),
                    )
                    .font(KinetixTypography.otpCode)
                    .tracking(8)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(KinetixPalette.textPrimary)
                    .tint(KinetixPalette.accent)
                    .keyboardType(.numberPad)
                    .textContentType(.oneTimeCode)
                    .focused($isCodeFocused)
                    .frame(maxWidth: .infinity, minHeight: 64)
                    .padding(.horizontal, KinetixTheme.spacingMedium)
                    .background(KinetixPalette.surface)
                    .clipShape(RoundedRectangle(cornerRadius: KinetixTheme.cornerRadiusControl))
                    .overlay(
                        RoundedRectangle(cornerRadius: KinetixTheme.cornerRadiusControl)
                            .stroke(
                                isCodeFocused
                                    ? KinetixPalette.accent
                                    : KinetixPalette.borderStrong,
                                lineWidth: isCodeFocused
                                    ? KinetixTheme.borderWidthFocused
                                    : KinetixTheme.borderWidthHairline,
                            )
                    )
                    .accessibilityLabel(Text(.twoFactorCodeLabel))
                }

                if state == .challengeClosed {
                    KinetixPrimaryButton(
                        title: .twoFactorReturnToSignIn,
                        action: onReturnToSignIn,
                    )
                } else {
                    KinetixPrimaryButton(
                        title: .twoFactorVerifyButton,
                        isLoading: state == .submitting,
                        isDisabled: !canSubmit,
                        action: {
                            isCodeFocused = false
                            onSubmit()
                        },
                    )
                }
            }
            .padding(.horizontal, KinetixTheme.spacingLarge)
            .padding(.bottom, KinetixTheme.spacingLarge)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(KinetixPalette.background.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private var statusSection: some View {
        switch state {
        case .idle, .submitting, .verified:
            EmptyView()
        case .wrongCode:
            KinetixStatusBanner(
                tone: .danger,
                message: .errorTwoFactorWrongCode,
            )
        case .challengeClosed:
            KinetixStatusBanner(
                tone: .warning,
                message: .twoFactorChallengeClosed,
            )
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
    TwoFactorChallengeContent(
        code: .constant(""),
        state: .wrongCode,
        canSubmit: false,
        failureMapper: FailureMessageMapper(),
        onSubmit: {},
        onReturnToSignIn: {},
    )
    .preferredColorScheme(.dark)
}
