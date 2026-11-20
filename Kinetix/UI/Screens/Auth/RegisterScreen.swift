import KinetixDomain
import KinetixPresentation
import SwiftUI

struct RegisterScreen: View {
    @State private var viewModel: RegisterViewModel
    private let failureMapper: FailureMessageMapper
    private let onRegistered: (AuthSession) -> Void

    init(
        viewModel: RegisterViewModel,
        failureMapper: FailureMessageMapper,
        onRegistered: @escaping (AuthSession) -> Void,
    ) {
        _viewModel = State(initialValue: viewModel)
        self.failureMapper = failureMapper
        self.onRegistered = onRegistered
    }

    var body: some View {
        RegisterContent(
            email: $viewModel.email,
            password: $viewModel.password,
            state: viewModel.state,
            canSubmit: viewModel.canSubmit,
            failureMapper: failureMapper,
            onSubmit: viewModel.submit,
        )
        .onChange(of: viewModel.state) { _, next in
            if case .registered(let session) = next {
                onRegistered(session)
            }
        }
        .onDisappear {
            viewModel.cancel()
        }
    }
}
