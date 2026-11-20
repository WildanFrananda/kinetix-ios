import KinetixPresentation
import SwiftUI

struct ProfileScreen: View {
    @State private var viewModel: ProfileViewModel
    private let failureMapper: FailureMessageMapper

    init(
        viewModel: ProfileViewModel,
        failureMapper: FailureMessageMapper,
    ) {
        _viewModel = State(initialValue: viewModel)
        self.failureMapper = failureMapper
    }

    var body: some View {
        ProfileContent(
            draft: $viewModel.draft,
            state: viewModel.state,
            saveState: viewModel.saveState,
            failureMapper: failureMapper,
            onSave: viewModel.save,
            onRefresh: viewModel.refresh,
        )
        .task {
            viewModel.start()
        }
        .onDisappear {
            viewModel.cancel()
        }
    }
}
