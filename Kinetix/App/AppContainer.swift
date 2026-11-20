import Foundation
import KinetixData
import KinetixDomain
import KinetixPresentation

final class AppContainer {
    private let configSource: any AppConfigSource
    private let configValidator: AppConfigValidator

    init(bundle: Bundle = .main) {
        self.configSource = BundleAppConfigSource(bundle: bundle)
        self.configValidator = AppConfigValidator()
    }

    func makeRootViewModel() -> AppRootViewModel {
        return AppRootViewModel(
            configSource: configSource,
            validator: configValidator,
        )
    }
}
