import Foundation
import KinetixDomain

public struct DefaultAuthRepository: AuthRepository {
    private let apiClient: IdentityAPIClient
    private let vault: any SessionVault
    private let cacheStore: any ProfileCacheStore
    private let routeStore: any RoutePersistenceStore
    private let analyticsTracker: any AnalyticsTracker
    private let crashReporter: any CrashReporter

    public init(
        apiClient: IdentityAPIClient,
        vault: any SessionVault,
        cacheStore: any ProfileCacheStore,
        routeStore: any RoutePersistenceStore,
        analyticsTracker: any AnalyticsTracker,
        crashReporter: any CrashReporter,
    ) {
        self.apiClient = apiClient
        self.vault = vault
        self.cacheStore = cacheStore
        self.routeStore = routeStore
        self.analyticsTracker = analyticsTracker
        self.crashReporter = crashReporter
    }

    public func signIn(
        email: String,
        password: String,
    ) async -> Result<SignInOutcome, Failure> {
        let result = await apiClient.login(email: email, password: password)
        switch result {
        case .failure(let failure):
            return .failure(failure)
        case .success(.twoFactorRequired(let challenge)):
            return .success(.twoFactorRequired(challenge))
        case .success(.signedIn(let session)):
            switch persistBuyerSession(session) {
            case .success:
                return .success(.signedIn(session))
            case .failure(let failure):
                return .failure(failure)
            }
        }
    }

    public func register(
        email: String,
        password: String,
    ) async -> Result<AuthSession, Failure> {
        let result = await apiClient.register(email: email, password: password)
        switch result {
        case .failure(let failure):
            return .failure(failure)
        case .success(let session):
            switch persistBuyerSession(session) {
            case .success:
                return .success(session)
            case .failure(let failure):
                return .failure(failure)
            }
        }
    }

    public func verifyTwoFactor(
        challengeToken: String,
        code: String,
    ) async -> Result<AuthSession, Failure> {
        let result = await apiClient.verifyTwoFactor(challengeToken: challengeToken, code: code)
        switch result {
        case .failure(let failure):
            return .failure(failure)
        case .success(let session):
            switch persistBuyerSession(session) {
            case .success:
                return .success(session)
            case .failure(let failure):
                return .failure(failure)
            }
        }
    }

    public func signOut() async -> Result<Void, Failure> {
        let stored = vault.read()
        if case .signedIn(let session) = stored {
            _ = await apiClient.logout(refreshToken: session.refreshToken)
            _ = await cacheStore.clearProfile(for: session.user.principalId)
            routeStore.clearPath(for: session.user.principalId)
        }

        analyticsTracker.setUserPrincipal(nil)
        crashReporter.setUserPrincipal(nil)
        return vault.clear()
    }

    private func persistBuyerSession(_ session: AuthSession) -> Result<Void, Failure> {
        guard session.user.role.isBuyerAccount else {
            return .failure(.unsupportedAccountRole)
        }

        switch vault.write(session) {
        case .success:
            analyticsTracker.setUserPrincipal(session.user.principalId)
            crashReporter.setUserPrincipal(session.user.principalId)
            return .success(())
        case .failure(let failure):
            return .failure(failure)
        }
    }
}
