import KinetixDomain
import KinetixPresentation
import SwiftUI
import UIKit

struct TwoFactorSettingsContent: View {
    @Binding var password: String
    @Binding var code: String
    let state: TwoFactorSettingsState
    let failureMapper: FailureMessageMapper
    let onSetup: () -> Void
    let onEnable: () -> Void
    let onDisable: () -> Void

    @State private var selectedTab: TwoFactorSettingsTab = .enable
    @State private var copiedSecret = false
    @FocusState private var focusedField: AuthFormField?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: KinetixTheme.spacingLarge) {
                Picker("", selection: $selectedTab) {
                    Text(.twoFactorTabEnable).tag(TwoFactorSettingsTab.enable)
                    Text(.twoFactorTabDisable).tag(TwoFactorSettingsTab.disable)
                }
                .pickerStyle(.segmented)
                .accessibilityLabel(Text(.twoFactorSettingsTitle))

                statusSection

                switch selectedTab {
                case .enable:
                    enableSection
                case .disable:
                    disableSection
                }
            }
            .padding(.horizontal, KinetixTheme.spacingLarge)
            .padding(.vertical, KinetixTheme.spacingMedium)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(KinetixPalette.background.ignoresSafeArea())
        .navigationTitle(Text(.twoFactorSettingsTitle))
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private var enableSection: some View {
        if case .setupReady(let setup) = state {
            VStack(alignment: .leading, spacing: KinetixTheme.spacingMedium) {
                KinetixSectionHeader(title: .twoFactorStepScanEyebrow)

                VStack(spacing: KinetixTheme.spacingMedium) {
                    QRCodeImageView(payload: setup.qrCodeURL)

                    Rectangle()
                        .fill(KinetixPalette.borderHairline)
                        .frame(height: KinetixTheme.borderWidthHairline)

                    VStack(alignment: .leading, spacing: KinetixTheme.spacingXSmall) {
                        Text(.twoFactorSecretLabel)
                            .font(KinetixTypography.fieldLabel)
                            .foregroundStyle(KinetixPalette.textSecondary)

                        HStack(spacing: KinetixTheme.spacingSmall) {
                            Text(setup.secret)
                                .font(KinetixTypography.labelMono)
                                .foregroundStyle(KinetixPalette.accentHigh)
                                .textSelection(.enabled)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            Button {
                                UIPasteboard.general.string = setup.secret
                                copiedSecret = true
                            } label: {
                                Label(
                                    copiedSecret
                                        ? LocalizedStringResource.twoFactorSecretCopied
                                        : LocalizedStringResource.twoFactorCopySecretButton,
                                    systemImage: copiedSecret ? "checkmark" : "doc.on.doc",
                                )
                                .font(KinetixTypography.fieldLabel)
                                .foregroundStyle(KinetixPalette.textPrimary)
                                .padding(.horizontal, KinetixTheme.spacingSmall)
                                .frame(minHeight: KinetixTheme.minTapTarget)
                                .background(KinetixPalette.surfaceElevated)
                                .clipShape(
                                    RoundedRectangle(cornerRadius: KinetixTheme.cornerRadiusControl)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: KinetixTheme.cornerRadiusControl)
                                        .stroke(
                                            KinetixPalette.borderStrong,
                                            lineWidth: KinetixTheme.borderWidthHairline,
                                        )
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(KinetixTheme.spacingMedium)
                .frame(maxWidth: .infinity)
                .background(KinetixPalette.surface)
                .clipShape(RoundedRectangle(cornerRadius: KinetixTheme.cornerRadiusCard))
                .overlay(
                    RoundedRectangle(cornerRadius: KinetixTheme.cornerRadiusCard)
                        .stroke(
                            KinetixPalette.borderHairline,
                            lineWidth: KinetixTheme.borderWidthHairline,
                        )
                )

                KinetixSectionHeader(title: .twoFactorStepConfirmEyebrow)

                KinetixTextField(
                    label: .authPasswordLabel,
                    placeholder: .authPasswordPlaceholder,
                    text: $password,
                    isSecure: true,
                    isFocused: focusedField == .password,
                    contentType: .password,
                    submitLabel: .next,
                    onSubmit: {
                        focusedField = nil
                    },
                )
                .focused($focusedField, equals: .password)

                KinetixTextField(
                    label: .twoFactorCodeLabel,
                    placeholder: .twoFactorCodePlaceholder,
                    text: $code,
                    keyboardType: .numberPad,
                    contentType: .oneTimeCode,
                )

                KinetixPrimaryButton(
                    title: .twoFactorEnableButton,
                    isLoading: state == .submitting,
                    isDisabled: password.isEmpty || code.count != 6,
                    action: {
                        focusedField = nil
                        onEnable()
                    },
                )
            }
        } else {
            VStack(alignment: .leading, spacing: KinetixTheme.spacingMedium) {
                KinetixStatusBanner(
                    tone: .info,
                    message: .twoFactorSetupGuidance,
                )

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
                        onSetup()
                    },
                )
                .focused($focusedField, equals: .password)

                KinetixPrimaryButton(
                    title: .twoFactorSetupButton,
                    isLoading: state == .submitting,
                    isDisabled: password.isEmpty,
                    action: {
                        focusedField = nil
                        onSetup()
                    },
                )
            }
        }
    }

    private var disableSection: some View {
        VStack(alignment: .leading, spacing: KinetixTheme.spacingMedium) {
            KinetixStatusBanner(
                tone: .warning,
                message: .twoFactorDisableGuidance,
            )

            KinetixTextField(
                label: .authPasswordLabel,
                placeholder: .authPasswordPlaceholder,
                text: $password,
                isSecure: true,
                isFocused: focusedField == .password,
                contentType: .password,
                submitLabel: .next,
                onSubmit: {
                    focusedField = nil
                },
            )
            .focused($focusedField, equals: .password)

            KinetixTextField(
                label: .twoFactorCodeLabel,
                placeholder: .twoFactorCodePlaceholder,
                text: $code,
                keyboardType: .numberPad,
                contentType: .oneTimeCode,
            )

            Button {
                focusedField = nil
                onDisable()
            } label: {
                HStack(spacing: KinetixTheme.spacingSmall) {
                    if state == .submitting {
                        ProgressView()
                            .tint(KinetixPalette.dangerRed)
                    }

                    Text(.twoFactorDisableButton)
                        .font(KinetixTypography.title)
                        .foregroundStyle(KinetixPalette.dangerRed)
                }
                .frame(maxWidth: .infinity, minHeight: KinetixTheme.controlHeight)
                .background(KinetixPalette.surface)
                .clipShape(RoundedRectangle(cornerRadius: KinetixTheme.cornerRadiusControl))
                .overlay(
                    RoundedRectangle(cornerRadius: KinetixTheme.cornerRadiusControl)
                        .stroke(
                            KinetixPalette.dangerRed,
                            lineWidth: KinetixTheme.borderWidthHairline,
                        )
                )
            }
            .disabled(state == .submitting || password.isEmpty || code.count != 6)
        }
    }

    @ViewBuilder
    private var statusSection: some View {
        switch state {
        case .idle, .submitting, .setupReady:
            EmptyView()
        case .enabled:
            KinetixStatusBanner(tone: .success, message: .twoFactorEnabledMessage)
        case .disabled:
            KinetixStatusBanner(tone: .info, message: .twoFactorDisabledMessage)
        case .alreadyEnabled:
            KinetixStatusBanner(tone: .warning, message: .twoFactorAlreadyEnabledMessage)
        case .notEnabled:
            KinetixStatusBanner(tone: .warning, message: .twoFactorNotEnabledMessage)
        case .invalidCode:
            KinetixStatusBanner(tone: .danger, message: .errorTwoFactorWrongCode)
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
    TwoFactorSettingsContent(
        password: .constant(""),
        code: .constant(""),
        state: .idle,
        failureMapper: FailureMessageMapper(),
        onSetup: {},
        onEnable: {},
        onDisable: {},
    )
    .preferredColorScheme(.dark)
}
