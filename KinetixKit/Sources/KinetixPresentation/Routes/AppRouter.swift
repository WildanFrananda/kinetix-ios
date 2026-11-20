import Foundation
import KinetixDomain
import Observation

@Observable
public final class AppRouter {
    public var path: [AppRoute] = []
    public private(set) var pendingSessionRoute: AppRoute?
    public private(set) var activeChallenge: TwoFactorChallenge?

    private let persistenceStore: any RoutePersistenceStore
    private var activePrincipalId: PrincipalId?

    public init(persistenceStore: any RoutePersistenceStore) {
        self.persistenceStore = persistenceStore
    }

    public func navigate(
        to route: AppRoute,
        isAuthenticated: Bool,
    ) {
        if route.requiresSession && !isAuthenticated {
            pendingSessionRoute = route
            return
        }

        path.append(route)
        persistIfAuthenticated()
    }

    public func beginTwoFactorChallenge(_ challenge: TwoFactorChallenge) {
        activeChallenge = challenge
        path.append(.twoFactorChallenge)
    }

    public func popToRoot() {
        path.removeAll()
        activeChallenge = nil
        persistIfAuthenticated()
    }

    public func restoreSession(for principalId: PrincipalId) {
        activePrincipalId = principalId
        activeChallenge = nil

        if let pending = pendingSessionRoute {
            pendingSessionRoute = nil
            path = [pending]
            persistIfAuthenticated()
            return
        }

        guard let encoded = persistenceStore.loadEncodedPath(for: principalId) else {
            path = []
            return
        }

        guard let decoded = try? JSONDecoder().decode([AppRoute].self, from: encoded) else {
            persistenceStore.clearPath(for: principalId)
            path = []
            return
        }

        path = decoded.filter { $0.requiresSession }
    }

    public func persistCurrentPath() {
        persistIfAuthenticated()
    }

    public func clearSession(for principalId: PrincipalId?) {
        if let id = principalId ?? activePrincipalId {
            persistenceStore.clearPath(for: id)
        }

        activePrincipalId = nil
        pendingSessionRoute = nil
        activeChallenge = nil
        path = []
    }

    private func persistIfAuthenticated() {
        guard let principalId = activePrincipalId else {
            return
        }

        let persistable = path.filter { $0.requiresSession }
        if persistable.isEmpty {
            persistenceStore.clearPath(for: principalId)
            return
        }

        if let encoded = try? JSONEncoder().encode(persistable) {
            persistenceStore.saveEncodedPath(encoded, for: principalId)
        }
    }
}
