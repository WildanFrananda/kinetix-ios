import Foundation
import KinetixData
import KinetixDomain

nonisolated struct AppDependencies: Sendable {
    let clock: any AppClock
    let sessionRepository: any SessionRepository
    let authRepository: any AuthRepository
    let twoFactorRepository: any TwoFactorRepository
    let profileRepository: any ProfileRepository
    let outboxProcessor: OutboxProcessor

    init(
        config: AppConfig,
        clock: any AppClock,
        routeStore: any RoutePersistenceStore,
        protectedDataProvider: any ProtectedDataStatusProvider,
        analyticsTracker: any AnalyticsTracker,
        crashReporter: any CrashReporter,
    ) {
        self.clock = clock

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
        let apiClient = IdentityAPIClient(apiCaller: apiCaller, clock: clock)

        let cacheStore = SwiftDataProfileCacheStore(
            protectedDataProvider: protectedDataProvider
        )
        let outboxStore = SwiftDataOutboxStore(
            protectedDataProvider: protectedDataProvider,
            crashReporter: crashReporter,
        )
        let outboxExecutor = ProfileOutboxExecutor(
            apiClient: apiClient,
            cacheStore: cacheStore,
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
            apiClient: apiClient,
            cacheStore: cacheStore,
            routeStore: routeStore,
            outboxProcessor: processor,
            analyticsTracker: analyticsTracker,
            crashReporter: crashReporter,
        )
        self.authRepository = DefaultAuthRepository(
            apiClient: apiClient,
            vault: vault,
            cacheStore: cacheStore,
            routeStore: routeStore,
            analyticsTracker: analyticsTracker,
            crashReporter: crashReporter,
        )
        self.twoFactorRepository = DefaultTwoFactorRepository(apiClient: apiClient)
        self.profileRepository = DefaultProfileRepository(
            apiClient: apiClient,
            cacheStore: cacheStore,
            outboxProcessor: processor,
            outboxStore: outboxStore,
            clock: clock,
        )
    }
}
