import KinetixDomain
import KinetixPresentation
import SwiftUI

struct LanguageSettingsScreen: View {
    @Bindable var viewModel: LanguageSettingsViewModel

    var body: some View {
        LanguageSettingsContent(
            selectedLanguage: viewModel.selectedLanguage,
            onSelectLanguage: { language in
                viewModel.selectLanguage(language)
            },
        )
    }
}
