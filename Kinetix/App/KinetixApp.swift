import SwiftUI

@main
struct KinetixApp: App {
    @UIApplicationDelegateAdaptor(AppDelegateAdaptor.self) private var appDelegate
    private let container = AppContainer()

    var body: some Scene {
        WindowGroup {
            AppRootScreen(
                viewModel: container.makeRootViewModel(),
                container: container,
            )
            .preferredColorScheme(.dark)
        }
    }
}
