import SwiftUI

@main
struct KinetixApp: App {
    private let container = AppContainer()

    var body: some Scene {
        WindowGroup {
            AppRootScreen(viewModel: container.makeRootViewModel())
                .preferredColorScheme(.dark)
        }
    }
}
