import KinetixPresentation
import SwiftUI

struct TwoFactorSettingsScreen: View {
    @State private var viewModel: TwoFactorSettingsViewModel
    private let failureMapper: FailureMessageMapper

    init(
        viewModel: TwoFactorSettingsViewModel,
        failureMapper: FailureMessageMapper,
    ) {
        _viewModel = State(initialValue: viewModel)
        self.failureMapper = failureMapper
    }

    var body: some View {
        TwoFactorSettingsContent(
            password: $viewModel.password,
            code: $viewModel.code,
            state: viewModel.state,
            failureMapper: failureMapper,
            onSetup: viewModel.requestSetup,
            onEnable: viewModel.confirmEnable,
            onDisable: viewModel.disableTwoFactor,
        )
        .onDisappear {
            viewModel.cancel()
        }
    }
}
