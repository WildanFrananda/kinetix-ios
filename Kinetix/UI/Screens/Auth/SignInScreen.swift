import KinetixDomain
import KinetixPresentation
import SwiftUI

struct SignInScreen: View {
    @State private var viewModel: SignInViewModel
    private let failureMapper: FailureMessageMapper
    private let onSignedIn: (AuthSession) -> Void
    private let onTwoFactorRequired: (TwoFactorChallenge) -> Void
    private let onNavigateRegister: () -> Void

    init(
        viewModel: SignInViewModel,
        failureMapper: FailureMessageMapper,
        onSignedIn: @escaping (AuthSession) -> Void,
        onTwoFactorRequired: @escaping (TwoFactorChallenge) -> Void,
        onNavigateRegister: @escaping () -> Void,
    ) {
        _viewModel = State(initialValue: viewModel)
        self.failureMapper = failureMapper
        self.onSignedIn = onSignedIn
        self.onTwoFactorRequired = onTwoFactorRequired
        self.onNavigateRegister = onNavigateRegister
    }

    var body: some View {
        SignInContent(
            email: $viewModel.email,
            password: $viewModel.password,
            state: viewModel.state,
            canSubmit: viewModel.canSubmit,
            failureMapper: failureMapper,
            onSubmit: viewModel.submit,
            onNavigateRegister: onNavigateRegister,
        )
        .onChange(of: viewModel.state) { _, next in
            switch next {
            case .signedIn(let session):
                onSignedIn(session)
            case .twoFactorRequired(let challenge):
                onTwoFactorRequired(challenge)
            case .idle, .submitting, .rateLimited, .failed:
                break
            }
        }
        .onDisappear {
            viewModel.cancel()
        }
    }
}
