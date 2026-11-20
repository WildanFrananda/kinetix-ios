import BackgroundTasks
import Foundation
import KinetixData
import KinetixDomain
import KinetixPresentation

final class AppContainer {
    let router: AppRouter
    let languageSettingsViewModel: LanguageSettingsViewModel
    let failureMapper: FailureMessageMapper

    private let configSource: any AppConfigSource
    private let configValidator: AppConfigValidator
    private let clock: any AppClock
    private let routeStore: any RoutePersistenceStore
    private let languageStore: any LanguagePreferenceStore
    private let protectedDataProvider: any ProtectedDataStatusProvider
    private let analyticsTracker: any AnalyticsTracker
    private let crashReporter: any CrashReporter
    private var dependencies: AppDependencies?

    init(bundle: Bundle = .main) {
        self.configSource = BundleAppConfigSource(bundle: bundle)
        self.configValidator = AppConfigValidator()
        self.clock = SystemClock()
        let store = UserDefaultsRoutePersistenceStore()
        self.routeStore = store
        self.router = AppRouter(persistenceStore: store)
        let languageStore = UserDefaultsLanguagePreferenceStore()
        self.languageStore = languageStore
        self.languageSettingsViewModel = LanguageSettingsViewModel(store: languageStore)
        self.protectedDataProvider = UIKitProtectedDataStatusProvider()
        self.analyticsTracker = OSLogAnalyticsTracker()
        self.crashReporter = OSLogCrashReporter()
        self.failureMapper = FailureMessageMapper()
    }

    func makeRootViewModel() -> AppRootViewModel {
        let clock = self.clock
        let routeStore = self.routeStore
        let protectedData = self.protectedDataProvider
        let analytics = self.analyticsTracker
        let crash = self.crashReporter

        return AppRootViewModel(
            configSource: configSource,
            validator: configValidator,
            sessionRepositoryFactory: { config in
                let built = AppDependencies(
                    config: config,
                    clock: clock,
                    routeStore: routeStore,
                    protectedDataProvider: protectedData,
                    analyticsTracker: analytics,
                    crashReporter: crash,
                )
                return built.sessionRepository
            },
        )
    }

    func resolveDependencies(for config: AppConfig) -> AppDependencies {
        if let dependencies {
            return dependencies
        }

        let built = AppDependencies(
            config: config,
            clock: clock,
            routeStore: routeStore,
            protectedDataProvider: protectedDataProvider,
            analyticsTracker: analyticsTracker,
            crashReporter: crashReporter,
        )
        dependencies = built
        return built
    }

    func imagePipeline(for config: AppConfig) -> ImagePipeline {
        return resolveDependencies(for: config).imagePipeline
    }

    func makeCatalogHomeViewModel(config: AppConfig) -> CatalogHomeViewModel {
        let deps = resolveDependencies(for: config)
        return CatalogHomeViewModel(
            catalogRepository: deps.catalogRepository,
            pricingRepository: deps.pricingRepository,
        )
    }

    func makeProductDetailViewModel(
        config: AppConfig,
        sku: ProductSku,
    ) -> ProductDetailViewModel {
        let deps = resolveDependencies(for: config)
        return ProductDetailViewModel(
            sku: sku,
            catalogRepository: deps.catalogRepository,
            pricingRepository: deps.pricingRepository,
            reviewRepository: deps.reviewRepository,
        )
    }

    func makeSearchViewModel(config: AppConfig) -> SearchViewModel {
        let deps = resolveDependencies(for: config)
        return SearchViewModel(
            searchRepository: deps.searchRepository,
            catalogRepository: deps.catalogRepository,
            clock: deps.clock,
        )
    }

    func makeSignInViewModel(config: AppConfig) -> SignInViewModel {
        let deps = resolveDependencies(for: config)
        return SignInViewModel(authRepository: deps.authRepository, clock: deps.clock)
    }

    func makeRegisterViewModel(config: AppConfig) -> RegisterViewModel {
        let deps = resolveDependencies(for: config)
        return RegisterViewModel(authRepository: deps.authRepository, clock: deps.clock)
    }

    func makeTwoFactorChallengeViewModel(
        config: AppConfig,
        challenge: TwoFactorChallenge,
    ) -> TwoFactorChallengeViewModel {
        let deps = resolveDependencies(for: config)
        return TwoFactorChallengeViewModel(
            challenge: challenge,
            authRepository: deps.authRepository,
            clock: deps.clock,
        )
    }

    func makeAccountHomeViewModel(
        config: AppConfig,
        session: AuthSession,
    ) -> AccountHomeViewModel {
        let deps = resolveDependencies(for: config)
        return AccountHomeViewModel(
            session: session,
            authRepository: deps.authRepository,
        )
    }

    func makeTwoFactorSettingsViewModel(
        config: AppConfig,
        accountId: AccountId,
    ) -> TwoFactorSettingsViewModel {
        let deps = resolveDependencies(for: config)
        return TwoFactorSettingsViewModel(
            accountId: accountId,
            repository: deps.twoFactorRepository,
            clock: deps.clock,
        )
    }

    func makeProfileViewModel(
        config: AppConfig,
        accountId: AccountId,
        principalId: PrincipalId,
    ) -> ProfileViewModel {
        let deps = resolveDependencies(for: config)
        return ProfileViewModel(
            accountId: accountId,
            principalId: principalId,
            repository: deps.profileRepository,
        )
    }

    func scheduleBackgroundOutboxRefreshIfNeeded(
        config: AppConfig,
        principalId: PrincipalId,
    ) {
        let deps = resolveDependencies(for: config)
        Task {
            let hasPending = await deps.outboxProcessor.hasPendingEntries(for: principalId)
            guard hasPending else {
                return
            }

            let request = BGAppRefreshTaskRequest(
                identifier: AppDelegateAdaptor.outboxRefreshIdentifier
            )
            request.earliestBeginDate = Date(timeIntervalSinceNow: 60)
            try? BGTaskScheduler.shared.submit(request)
        }
    }
}
