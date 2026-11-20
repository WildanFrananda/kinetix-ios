import SwiftUI

struct KinetixTextField: View {
    let label: LocalizedStringResource
    let placeholder: LocalizedStringResource
    @Binding var text: String
    let isSecure: Bool
    let isFocused: Bool
    let keyboardType: UIKeyboardType
    let contentType: UITextContentType?
    let autocapitalization: TextInputAutocapitalization
    let submitLabel: SubmitLabel
    let onSubmit: () -> Void

    @State private var isPasswordVisible = false

    init(
        label: LocalizedStringResource,
        placeholder: LocalizedStringResource,
        text: Binding<String>,
        isSecure: Bool = false,
        isFocused: Bool = false,
        keyboardType: UIKeyboardType = .default,
        contentType: UITextContentType? = nil,
        autocapitalization: TextInputAutocapitalization = .never,
        submitLabel: SubmitLabel = .done,
        onSubmit: @escaping () -> Void = {},
    ) {
        self.label = label
        self.placeholder = placeholder
        self._text = text
        self.isSecure = isSecure
        self.isFocused = isFocused
        self.keyboardType = keyboardType
        self.contentType = contentType
        self.autocapitalization = autocapitalization
        self.submitLabel = submitLabel
        self.onSubmit = onSubmit
    }

    var body: some View {
        VStack(alignment: .leading, spacing: KinetixTheme.spacingXSmall) {
            Text(label)
                .font(KinetixTypography.fieldLabel)
                .foregroundStyle(
                    isFocused ? KinetixPalette.textPrimary : KinetixPalette.textSecondary
                )

            HStack(spacing: KinetixTheme.spacingSmall) {
                Group {
                    if isSecure && !isPasswordVisible {
                        SecureField(
                            "",
                            text: $text,
                            prompt: Text(placeholder).foregroundStyle(KinetixPalette.textTertiary),
                        )
                    } else {
                        TextField(
                            "",
                            text: $text,
                            prompt: Text(placeholder).foregroundStyle(KinetixPalette.textTertiary),
                        )
                    }
                }
                .font(KinetixTypography.body)
                .foregroundStyle(KinetixPalette.textPrimary)
                .tint(KinetixPalette.accent)
                .keyboardType(keyboardType)
                .textContentType(contentType)
                .textInputAutocapitalization(autocapitalization)
                .autocorrectionDisabled(true)
                .submitLabel(submitLabel)
                .onSubmit(onSubmit)
                .accessibilityLabel(Text(label))

                if isSecure {
                    Button {
                        isPasswordVisible.toggle()
                    } label: {
                        Image(systemName: isPasswordVisible ? "eye" : "eye.slash")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(KinetixPalette.textTertiary)
                            .frame(
                                width: KinetixTheme.minTapTarget,
                                height: KinetixTheme.minTapTarget,
                            )
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(
                        Text(
                            isPasswordVisible
                                ? .authHidePasswordAccessibility
                                : .authShowPasswordAccessibility
                        )
                    )
                }
            }
            .padding(.leading, KinetixTheme.spacingMedium)
            .padding(.trailing, isSecure ? KinetixTheme.spacingXSmall : KinetixTheme.spacingMedium)
            .frame(minHeight: KinetixTheme.controlHeight)
            .background(KinetixPalette.surface)
            .clipShape(RoundedRectangle(cornerRadius: KinetixTheme.cornerRadiusControl))
            .overlay(
                RoundedRectangle(cornerRadius: KinetixTheme.cornerRadiusControl)
                    .stroke(
                        isFocused ? KinetixPalette.accent : KinetixPalette.borderStrong,
                        lineWidth: isFocused
                            ? KinetixTheme.borderWidthFocused
                            : KinetixTheme.borderWidthHairline,
                    )
            )
        }
    }
}
