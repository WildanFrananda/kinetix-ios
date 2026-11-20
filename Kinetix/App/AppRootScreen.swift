import KinetixPresentation
import SwiftUI

struct AppRootScreen: View {
    @State private var viewModel: AppRootViewModel

    init(viewModel: AppRootViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        Group {
            switch viewModel.state {
            case .validating:
                VStack(spacing: KinetixTheme.spacingMedium) {
                    ProgressView()
                        .tint(KinetixPalette.electricVolt)

                    Text(.startupValidatingLabel)
                        .font(KinetixTypography.body)
                        .foregroundStyle(KinetixPalette.textSecondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(KinetixPalette.obsidianSurface.ignoresSafeArea())
            case .invalidConfiguration(let issues):
                ConfigErrorScreen(issues: issues)
            case .configured:
                VStack(spacing: KinetixTheme.spacingSmall) {
                    Text(.startupReadyTitle)
                        .font(KinetixTypography.headline)
                        .foregroundStyle(KinetixPalette.textPrimary)

                    Text(.startupReadySubtitle)
                        .font(KinetixTypography.body)
                        .foregroundStyle(KinetixPalette.textSecondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(KinetixPalette.obsidianSurface.ignoresSafeArea())
            }
        }
        .task {
            viewModel.start()
        }
    }
}
