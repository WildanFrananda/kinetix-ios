import KinetixDomain
import KinetixPresentation
import SwiftUI

struct AccountHomeScreen: View {
    @State private var viewModel: AccountHomeViewModel
    private let onOpenProfile: () -> Void
    private let onOpenTwoFactor: () -> Void
    private let onSignedOut: () -> Void

    init(
        viewModel: AccountHomeViewModel,
        onOpenProfile: @escaping () -> Void,
        onOpenTwoFactor: @escaping () -> Void,
        onSignedOut: @escaping () -> Void,
    ) {
        _viewModel = State(initialValue: viewModel)
        self.onOpenProfile = onOpenProfile
        self.onOpenTwoFactor = onOpenTwoFactor
        self.onSignedOut = onSignedOut
    }

    var body: some View {
        AccountHomeContent(
            email: viewModel.session.user.email,
            isSigningOut: viewModel.state == .signingOut,
            onOpenProfile: onOpenProfile,
            onOpenTwoFactor: onOpenTwoFactor,
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
