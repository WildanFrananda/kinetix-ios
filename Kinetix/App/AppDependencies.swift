import Foundation
import KinetixData
import KinetixDomain

nonisolated struct AppDependencies: Sendable {
    let clock: any AppClock
    let sessionRepository: any SessionRepository
    let authRepository: any AuthRepository
    let twoFactorRepository: any TwoFactorRepository
    let profileRepository: any ProfileRepository
    let catalogRepository: any CatalogRepository
    let pricingRepository: any PricingRepository
    let searchRepository: any SearchRepository
    let reviewRepository: any ReviewRepository
    let outboxProcessor: OutboxProcessor
    let imagePipeline: ImagePipeline

    init(
        config: AppConfig,
        clock: any AppClock,
        routeStore: any RoutePersistenceStore,
        protectedDataProvider: any ProtectedDataStatusProvider,
        analyticsTracker: any AnalyticsTracker,
        crashReporter: any CrashReporter,
    ) {
        self.clock = clock
        self.imagePipeline = ImagePipeline()

        let vault = KeychainSessionVault()
        let markerStore = UserDefaultsFirstLaunchMarkerStore()
        let firstLaunchCleaner = FirstLaunchSessionCleaner(
            vault: vault,
            markerStore: markerStore,
            protectedDataProvider: protectedDataProvider,
        )

        let transport = URLSessionHTTPTransport(baseURL: config.httpBaseURL)
        let refreshTransport = TokenRefreshTransport(transport: transport, clock: clock)
        let sessionRenewer = SessionRenewer(
            vault: vault,
            refreshTransport: refreshTransport,
            clock: clock,
        )
        let apiCaller = SafeApiCaller(transport: transport, sessionRenewer: sessionRenewer)
        let identityClient = IdentityAPIClient(apiCaller: apiCaller, clock: clock)
        let catalogClient = CatalogAPIClient(apiCaller: apiCaller)
        let pricingClient = PricingAPIClient(apiCaller: apiCaller)
        let searchClient = SearchAPIClient(apiCaller: apiCaller)
        let reviewClient = ReviewAPIClient(apiCaller: apiCaller)

        let cacheFactory = SwiftDataCacheContainerFactory()
        let profileCacheStore = SwiftDataProfileCacheStore(
            factory: cacheFactory,
            protectedDataProvider: protectedDataProvider,
        )
        let catalogCacheStore = SwiftDataCatalogCacheStore(
            factory: cacheFactory,
            protectedDataProvider: protectedDataProvider,
        )
        let outboxStore = SwiftDataOutboxStore(
            protectedDataProvider: protectedDataProvider,
            crashReporter: crashReporter,
        )
        let outboxExecutor = ProfileOutboxExecutor(
            apiClient: identityClient,
            cacheStore: profileCacheStore,
            clock: clock,
        )
        let processor = OutboxProcessor(
            outboxStore: outboxStore,
            executor: outboxExecutor,
            clock: clock,
            analyticsTracker: analyticsTracker,
            crashReporter: crashReporter,
        )
        self.outboxProcessor = processor

        self.sessionRepository = DefaultSessionRepository(
            vault: vault,
            firstLaunchCleaner: firstLaunchCleaner,
            apiClient: identityClient,
            cacheStore: profileCacheStore,
            routeStore: routeStore,
            outboxProcessor: processor,
            analyticsTracker: analyticsTracker,
            crashReporter: crashReporter,
        )
        self.authRepository = DefaultAuthRepository(
            apiClient: identityClient,
            vault: vault,
            cacheStore: profileCacheStore,
            routeStore: routeStore,
            analyticsTracker: analyticsTracker,
            crashReporter: crashReporter,
        )
        self.twoFactorRepository = DefaultTwoFactorRepository(apiClient: identityClient)
        self.profileRepository = DefaultProfileRepository(
            apiClient: identityClient,
            cacheStore: profileCacheStore,
            outboxProcessor: processor,
            outboxStore: outboxStore,
            clock: clock,
        )
        self.catalogRepository = DefaultCatalogRepository(
            apiClient: catalogClient,
            cacheStore: catalogCacheStore,
            clock: clock,
        )
        self.pricingRepository = DefaultPricingRepository(apiClient: pricingClient)
        self.searchRepository = DefaultSearchRepository(apiClient: searchClient)
        self.reviewRepository = DefaultReviewRepository(apiClient: reviewClient)
    }
}
