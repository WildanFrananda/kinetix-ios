import KinetixDomain
import KinetixPresentation
import SwiftUI

struct ProfileContent: View {
    @Binding var draft: ProfileDraft
    let state: ProfileScreenState
    let saveState: ProfileSaveState
    let failureMapper: FailureMessageMapper
    let onSave: () -> Void
    let onRefresh: () -> Void

    @FocusState private var focusedField: ProfileFormField?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: KinetixTheme.spacingLarge) {
                stateBanner
                saveBanner

                switch state {
                case .idle, .loading:
                    loadingCard
                case .failed(let failure):
                    VStack(alignment: .leading, spacing: KinetixTheme.spacingMedium) {
                        KinetixStatusBanner(
                            tone: .danger,
                            message: failureMapper.message(for: failure),
                        )

                        KinetixPrimaryButton(
                            title: .commonRetryButton,
                            action: onRefresh,
                        )
                    }
                case .notCreated, .loaded, .cachedStale, .pendingLocalSync:
                    formSections
                }
            }
            .padding(.horizontal, KinetixTheme.spacingMedium)
            .padding(.vertical, KinetixTheme.spacingMedium)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(KinetixPalette.background.ignoresSafeArea())
        .navigationTitle(Text(.profileTitle))
        .navigationBarTitleDisplayMode(.inline)
        .refreshable {
            onRefresh()
        }
        .safeAreaInset(edge: .bottom) {
            if showsSaveBar {
                VStack(spacing: 0) {
                    Rectangle()
                        .fill(KinetixPalette.borderHairline)
                        .frame(height: KinetixTheme.borderWidthHairline)

                    KinetixPrimaryButton(
                        title: .profileSaveButton,
                        isLoading: saveState == .saving,
                        isDisabled: saveState == .saving,
                        action: {
                            focusedField = nil
                            onSave()
                        },
                    )
                    .padding(.horizontal, KinetixTheme.spacingMedium)
                    .padding(.top, 12)
                    .padding(.bottom, KinetixTheme.spacingSmall)
                    .background(KinetixPalette.background)
                }
            }
        }
    }

    private var showsSaveBar: Bool {
        switch state {
        case .notCreated, .loaded, .cachedStale, .pendingLocalSync:
            return true
        case .idle, .loading, .failed:
            return false
        }
    }

    private var loadingCard: some View {
        HStack(spacing: KinetixTheme.spacingSmall) {
            ProgressView()
                .tint(KinetixPalette.accent)

            Text(.profileLoadingLabel)
                .font(KinetixTypography.body)
                .foregroundStyle(KinetixPalette.textSecondary)
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

    private var formSections: some View {
        VStack(alignment: .leading, spacing: KinetixTheme.spacingLarge) {
            VStack(alignment: .leading, spacing: KinetixTheme.spacingSmall) {
                KinetixSectionHeader(title: .profileSectionContact)

                VStack(spacing: 0) {
                    KinetixGroupedInputRow(
                        label: .profileFullNameLabel,
                        placeholder: .profileFullNamePlaceholder,
                        text: $draft.fullName,
                        isFocused: focusedField == .fullName,
                        contentType: .name,
                        autocapitalization: .words,
                        submitLabel: .next,
                        onSubmit: { focusedField = .phoneNumber },
                    )
                    .focused($focusedField, equals: .fullName)

                    insetDivider

                    KinetixGroupedInputRow(
                        label: .profilePhoneLabel,
                        placeholder: .profilePhonePlaceholder,
                        text: $draft.phoneNumber,
                        isFocused: focusedField == .phoneNumber,
                        keyboardType: .phonePad,
                        contentType: .telephoneNumber,
                        submitLabel: .next,
                        onSubmit: { focusedField = .streetAddress },
                    )
                    .focused($focusedField, equals: .phoneNumber)
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
                KinetixSectionHeader(title: .profileSectionAddress)

                VStack(spacing: 0) {
                    KinetixGroupedInputRow(
                        label: .profileStreetAddressLabel,
                        placeholder: .profileStreetAddressPlaceholder,
                        text: $draft.streetAddress,
                        isFocused: focusedField == .streetAddress,
                        contentType: .fullStreetAddress,
                        autocapitalization: .sentences,
                        submitLabel: .next,
                        onSubmit: { focusedField = .city },
                    )
                    .focused($focusedField, equals: .streetAddress)

                    fullDivider

                    HStack(spacing: 0) {
                        KinetixGroupedInputRow(
                            label: .profileCityLabel,
                            placeholder: .profileCityPlaceholder,
                            text: $draft.city,
                            isFocused: focusedField == .city,
                            contentType: .addressCity,
                            autocapitalization: .words,
                            submitLabel: .next,
                            onSubmit: { focusedField = .postalCode },
                        )
                        .focused($focusedField, equals: .city)

                        Rectangle()
                            .fill(KinetixPalette.borderHairline)
                            .frame(width: KinetixTheme.borderWidthHairline)

                        KinetixGroupedInputRow(
                            label: .profilePostalCodeLabel,
                            placeholder: .profilePostalCodePlaceholder,
                            text: $draft.postalCode,
                            isFocused: focusedField == .postalCode,
                            keyboardType: .numbersAndPunctuation,
                            contentType: .postalCode,
                            submitLabel: .next,
                            onSubmit: { focusedField = .avatarURL },
                        )
                        .focused($focusedField, equals: .postalCode)
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

            VStack(alignment: .leading, spacing: KinetixTheme.spacingSmall) {
                KinetixSectionHeader(title: .profileSectionAvatar)

                KinetixGroupedInputRow(
                    label: .profileAvatarUrlLabel,
                    placeholder: .profileAvatarUrlPlaceholder,
                    text: $draft.avatarURL,
                    isFocused: focusedField == .avatarURL,
                    keyboardType: .URL,
                    contentType: .URL,
                    submitLabel: .done,
                    onSubmit: {
                        focusedField = nil
                        onSave()
                    },
                )
                .focused($focusedField, equals: .avatarURL)
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
    }

    private var insetDivider: some View {
        Rectangle()
            .fill(KinetixPalette.borderHairline)
            .frame(height: KinetixTheme.borderWidthHairline)
            .padding(.leading, KinetixTheme.spacingMedium)
    }

    private var fullDivider: some View {
        Rectangle()
            .fill(KinetixPalette.borderHairline)
            .frame(height: KinetixTheme.borderWidthHairline)
    }

    @ViewBuilder
    private var stateBanner: some View {
        switch state {
        case .notCreated:
            KinetixStatusBanner(tone: .info, message: .profileNotCreatedNotice)
        case .loaded:
            KinetixStatusBanner(tone: .info, message: .profileCheckoutHint)
        case .cachedStale:
            KinetixStatusBanner(tone: .warning, message: .profileCachedStaleNotice)
        case .pendingLocalSync:
            KinetixStatusBanner(tone: .warning, message: .profileSavedLocallyNotice)
        case .idle, .loading, .failed:
            EmptyView()
        }
    }

    @ViewBuilder
    private var saveBanner: some View {
        switch saveState {
        case .idle, .saving:
            EmptyView()
        case .savedConfirmed:
            KinetixStatusBanner(tone: .success, message: .profileSavedConfirmedNotice)
        case .savedLocallyPendingSync:
            KinetixStatusBanner(tone: .warning, message: .profileSavedLocallyNotice)
        case .failed(let failure):
            KinetixStatusBanner(
                tone: .danger,
                message: failureMapper.message(for: failure),
            )
        }
    }
}

#Preview {
    NavigationStack {
        ProfileContent(
            draft: .constant(ProfileDraft()),
            state: .notCreated,
            saveState: .idle,
            failureMapper: FailureMessageMapper(),
            onSave: {},
            onRefresh: {},
        )
    }
    .preferredColorScheme(.dark)
}
