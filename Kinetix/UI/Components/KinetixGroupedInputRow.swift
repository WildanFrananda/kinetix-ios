import SwiftUI

struct KinetixGroupedInputRow: View {
    let label: LocalizedStringResource
    let placeholder: LocalizedStringResource
    @Binding var text: String
    let isFocused: Bool
    let keyboardType: UIKeyboardType
    let contentType: UITextContentType?
    let autocapitalization: TextInputAutocapitalization
    let submitLabel: SubmitLabel
    let onSubmit: () -> Void

    init(
        label: LocalizedStringResource,
        placeholder: LocalizedStringResource,
        text: Binding<String>,
        isFocused: Bool = false,
        keyboardType: UIKeyboardType = .default,
        contentType: UITextContentType? = nil,
        autocapitalization: TextInputAutocapitalization = .never,
        submitLabel: SubmitLabel = .next,
        onSubmit: @escaping () -> Void = {},
    ) {
        self.label = label
        self.placeholder = placeholder
        self._text = text
        self.isFocused = isFocused
        self.keyboardType = keyboardType
        self.contentType = contentType
        self.autocapitalization = autocapitalization
        self.submitLabel = submitLabel
        self.onSubmit = onSubmit
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(KinetixTypography.fieldLabel)
                .foregroundStyle(
                    isFocused ? KinetixPalette.accent : KinetixPalette.textSecondary
                )

            TextField(
                "",
                text: $text,
                prompt: Text(placeholder).foregroundStyle(KinetixPalette.textTertiary),
            )
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
        }
        .padding(.horizontal, KinetixTheme.spacingMedium)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, minHeight: 62, alignment: .leading)
        .background(isFocused ? KinetixPalette.surfaceElevated : KinetixPalette.surface)
    }
}
