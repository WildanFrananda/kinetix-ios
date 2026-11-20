import Foundation
import KinetixDomain

public struct DefaultSessionRepository: SessionRepository {
    private let vault: any SessionVault
    private let firstLaunchCleaner: FirstLaunchSessionCleaner
    private let apiClient: IdentityAPIClient
    private let cacheStore: any ProfileCacheStore
    private let routeStore: any RoutePersistenceStore
    private let outboxProcessor: OutboxProcessor
    private let analyticsTracker: any AnalyticsTracker
    private let crashReporter: any CrashReporter

    public init(
        vault: any SessionVault,
        firstLaunchCleaner: FirstLaunchSessionCleaner,
        apiClient: IdentityAPIClient,
        cacheStore: any ProfileCacheStore,
        routeStore: any RoutePersistenceStore,
        outboxProcessor: OutboxProcessor,
        analyticsTracker: any AnalyticsTracker,
        crashReporter: any CrashReporter,
    ) {
        self.vault = vault
        self.firstLaunchCleaner = firstLaunchCleaner
        self.apiClient = apiClient
        self.cacheStore = cacheStore
        self.routeStore = routeStore
        self.outboxProcessor = outboxProcessor
        self.analyticsTracker = analyticsTracker
        self.crashReporter = crashReporter
    }

    public func readStoredSession() async -> Result<StoredSessionState, Failure> {
        return .success(vault.read())
    }

    public func handleFirstLaunchCleanupIfNeeded() async -> Result<Void, Failure> {
        return firstLaunchCleaner.runOnForegroundActivation()
    }

    public func restoreAndVerifySession() async -> Result<AuthSession?, Failure> {
        switch vault.read() {
        case .unreadable:
            return .failure(.sessionUnavailable)
        case .signedOut:
            analyticsTracker.setUserPrincipal(nil)
            crashReporter.setUserPrincipal(nil)
            return .success(nil)
        case .signedIn(let stored):
            let checkResult = await apiClient.fetchMe()
            switch checkResult {
            case .success(let me):
                guard me.role.isBuyerAccount else {
                    _ = await clearPrincipalSession(principalId: stored.user.principalId)
                    return .failure(.unsupportedAccountRole)
                }

                let refreshed = resolveLatestSession(fallback: stored, verified: me)
                analyticsTracker.setUserPrincipal(refreshed.user.principalId)
                crashReporter.setUserPrincipal(refreshed.user.principalId)
                return .success(refreshed)
            case .failure(.sessionExpired):
                _ = await clearPrincipalSession(principalId: stored.user.principalId)
                return .success(nil)
            case .failure(let failure):
                return .failure(failure)
            }
        }
    }

    public func clearLocalSession() async -> Result<Void, Failure> {
        if case .signedIn(let session) = vault.read() {
            return await clearPrincipalSession(principalId: session.user.principalId)
        }

        analyticsTracker.setUserPrincipal(nil)
        crashReporter.setUserPrincipal(nil)
        return vault.clear()
    }

    public func drainPendingOutbox() async -> Result<Int, Failure> {
        switch vault.read() {
        case .unreadable:
            return .failure(.sessionUnavailable)
        case .signedOut:
            return .success(0)
        case .signedIn(let session):
            switch await outboxProcessor.drain(for: session.user.principalId) {
            case .success(let outcome):
                return .success(outcome.syncedCount)
            case .failure(let failure):
                return .failure(failure)
            }
        }
    }

    private func clearPrincipalSession(principalId: PrincipalId) async -> Result<Void, Failure> {
        _ = await cacheStore.clearProfile(for: principalId)
        routeStore.clearPath(for: principalId)
        analyticsTracker.setUserPrincipal(nil)
        crashReporter.setUserPrincipal(nil)
        return vault.clear()
    }

    private func resolveLatestSession(
        fallback: AuthSession,
        verified: SessionCheckResult,
    ) -> AuthSession {
        let base: AuthSession
        if case .signedIn(let current) = vault.read() {
            base = current
        } else {
            base = fallback
        }

        let updatedUser = UserIdentity(
            accountId: verified.accountId,
            principalId: verified.principalId,
            email: verified.email,
            role: verified.role,
        )
        let updatedSession = AuthSession(
            accessToken: base.accessToken,
            refreshToken: base.refreshToken,
            expiresAt: verified.expiresAt,
            user: updatedUser,
        )
        _ = vault.write(updatedSession)
        return updatedSession
    }
}
