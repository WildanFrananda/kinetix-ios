import Foundation
import KinetixDomain
import Observation

@Observable
public final class AppRootViewModel {
    public private(set) var state: AppStartupState = .validating

    private let configSource: any AppConfigSource
    private let validator: AppConfigValidator

    public init(
        configSource: any AppConfigSource,
        validator: AppConfigValidator,
    ) {
        self.configSource = configSource
        self.validator = validator
    }

    public func start() {
        guard state == .validating else {
            return
        }

        let input = configSource.readRawConfig()
        switch validator.validate(input) {
        case .success(let config):
            state = .configured(config)
        case .failure(let error):
            state = .invalidConfiguration(error.issues)
        }
    }
}
