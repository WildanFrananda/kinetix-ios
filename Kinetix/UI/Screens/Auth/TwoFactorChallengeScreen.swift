import KinetixDomain
import KinetixPresentation
import SwiftUI

struct TwoFactorChallengeScreen: View {
    @State private var viewModel: TwoFactorChallengeViewModel
    private let failureMapper: FailureMessageMapper
    private let onVerified: (AuthSession) -> Void
    private let onReturnToSignIn: () -> Void

    init(
        viewModel: TwoFactorChallengeViewModel,
        failureMapper: FailureMessageMapper,
        onVerified: @escaping (AuthSession) -> Void,
        onReturnToSignIn: @escaping () -> Void,
    ) {
        _viewModel = State(initialValue: viewModel)
        self.failureMapper = failureMapper
        self.onVerified = onVerified
        self.onReturnToSignIn = onReturnToSignIn
    }

    var body: some View {
        TwoFactorChallengeContent(
            code: $viewModel.code,
            state: viewModel.state,
            canSubmit: viewModel.canSubmit,
            failureMapper: failureMapper,
            onSubmit: viewModel.submit,
            onReturnToSignIn: onReturnToSignIn,
        )
        .onChange(of: viewModel.state) { _, next in
            if case .verified(let session) = next {
                onVerified(session)
            }
        }
        .onDisappear {
            viewModel.cancel()
        }
    }
}
