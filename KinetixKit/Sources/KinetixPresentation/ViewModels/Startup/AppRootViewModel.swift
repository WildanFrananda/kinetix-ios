import Foundation
import KinetixDomain
import Observation

@Observable
public final class AppRootViewModel {
    public private(set) var state: AppStartupState = .validating

    private let configSource: any AppConfigSource
    private let validator: AppConfigValidator
    private let sessionRepositoryFactory: (@Sendable (AppConfig) -> any SessionRepository)?
    private var activeTask: Task<Void, Never>?
    private var resolvedConfig: AppConfig?
    private var sessionRepository: (any SessionRepository)?

    public init(
        configSource: any AppConfigSource,
        validator: AppConfigValidator,
        sessionRepositoryFactory: (@Sendable (AppConfig) -> any SessionRepository)? = nil,
    ) {
        self.configSource = configSource
        self.validator = validator
        self.sessionRepositoryFactory = sessionRepositoryFactory
    }

    public func start() {
        guard state == .validating else {
            return
        }

        let input = configSource.readRawConfig()
        switch validator.validate(input) {
        case .failure(let error):
            state = .invalidConfiguration(error.issues)
        case .success(let config):
            resolvedConfig = config
            guard let factory = sessionRepositoryFactory else {
                state = .configured(config)
                return
            }

            let repository = factory(config)
            sessionRepository = repository
            state = .checkingSession(config)
            beginSessionRestore(config: config, repository: repository)
        }
    }

    public func retrySessionCheck() {
        guard let config = resolvedConfig, let repository = sessionRepository else {
            return
        }

        state = .checkingSession(config)
        beginSessionRestore(config: config, repository: repository)
    }

    public func onBecomeActive() {
        guard let config = resolvedConfig, let repository = sessionRepository else {
            return
        }

        switch state {
        case .sessionCheckFailed:
            state = .checkingSession(config)
            beginSessionRestore(config: config, repository: repository)
        case .signedIn:
            activeTask?.cancel()
            activeTask = Task {
                _ = await repository.drainPendingOutbox()
            }
        case .validating, .invalidConfiguration, .configured, .checkingSession, .signedOut:
            break
        }
    }

    public func didSignIn(_ session: AuthSession) {
        guard let config = resolvedConfig else {
            return
        }

        state = .signedIn(config, session)
        if let repository = sessionRepository {
            activeTask?.cancel()
            activeTask = Task {
                _ = await repository.drainPendingOutbox()
            }
        }
    }

    public func didSignOut() {
        guard let config = resolvedConfig else {
            return
        }

        activeTask?.cancel()
        state = .signedOut(config)
    }

    private func beginSessionRestore(
        config: AppConfig,
        repository: any SessionRepository,
    ) {
        activeTask?.cancel()
        activeTask = Task {
            let cleanupResult = await repository.handleFirstLaunchCleanupIfNeeded()
            if case .failure(let failure) = cleanupResult {
                state = .sessionCheckFailed(config, failure)
                return
            }

            let restoreResult = await repository.restoreAndVerifySession()
            switch restoreResult {
            case .success(let session):
                if let session {
                    state = .signedIn(config, session)
                    _ = await repository.drainPendingOutbox()
                } else {
                    state = .signedOut(config)
                }
            case .failure(.cancelled):
                break
            case .failure(let failure):
                state = .sessionCheckFailed(config, failure)
            }
        }
    }
}
