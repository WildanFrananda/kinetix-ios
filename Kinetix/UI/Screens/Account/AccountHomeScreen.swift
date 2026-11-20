import KinetixDomain
import KinetixPresentation
import SwiftUI

struct AccountHomeScreen: View {
    @State private var viewModel: AccountHomeViewModel
    private let selectedLanguage: AppLanguage
    private let onOpenProfile: () -> Void
    private let onOpenTwoFactor: () -> Void
    private let onOpenLanguageSettings: () -> Void
    private let onSignedOut: () -> Void

    init(
        viewModel: AccountHomeViewModel,
        selectedLanguage: AppLanguage,
        onOpenProfile: @escaping () -> Void,
        onOpenTwoFactor: @escaping () -> Void,
        onOpenLanguageSettings: @escaping () -> Void,
        onSignedOut: @escaping () -> Void,
    ) {
        _viewModel = State(initialValue: viewModel)
        self.selectedLanguage = selectedLanguage
        self.onOpenProfile = onOpenProfile
        self.onOpenTwoFactor = onOpenTwoFactor
        self.onOpenLanguageSettings = onOpenLanguageSettings
        self.onSignedOut = onSignedOut
    }

    var body: some View {
        AccountHomeContent(
            email: viewModel.session.user.email,
            isSigningOut: viewModel.state == .signingOut,
            selectedLanguage: selectedLanguage,
            onOpenProfile: onOpenProfile,
            onOpenTwoFactor: onOpenTwoFactor,
            onOpenLanguageSettings: onOpenLanguageSettings,
            onSignOut: viewModel.signOut,
        )
        .onChange(of: viewModel.state) { _, next in
            if next == .signedOut {
                onSignedOut()
            }
        }
        .onDisappear {
            viewModel.cancel()
        }
    }
}
