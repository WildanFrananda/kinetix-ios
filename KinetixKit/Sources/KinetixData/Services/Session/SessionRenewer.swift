import Foundation
import KinetixDomain

public actor SessionRenewer {
    public static let renewalLeadSeconds: TimeInterval = 60

    private let vault: any SessionVault
    private let refreshTransport: TokenRefreshTransport
    private let clock: any AppClock
    private var inFlightTask: Task<Result<AuthSession, Failure>, Never>?

    public init(
        vault: any SessionVault,
        refreshTransport: TokenRefreshTransport,
        clock: any AppClock,
    ) {
        self.vault = vault
        self.refreshTransport = refreshTransport
        self.clock = clock
    }

    public func validAccessSession(
        forceRefresh: Bool = false,
        isBackgroundLaunch: Bool = false,
    ) async -> Result<AuthSession, Failure> {
        switch vault.read() {
        case .unreadable:
            return .failure(.sessionUnavailable)
        case .signedOut:
            return .failure(.sessionExpired)
        case .signedIn(let session):
            let remaining = session.expiresAt.timeIntervalSince(clock.now())
            if !forceRefresh && remaining > Self.renewalLeadSeconds {
                return .success(session)
            }

            if isBackgroundLaunch {
                return remaining > 0 ? .success(session) : .failure(.sessionExpired)
            }

            return await singleFlightRefresh(currentSession: session)
        }
    }

    private func singleFlightRefresh(
        currentSession: AuthSession
    ) async -> Result<AuthSession, Failure> {
        if let existingTask = inFlightTask {
            return await existingTask.value
        }

        let refreshToken = currentSession.refreshToken
        let task = Task<Result<AuthSession, Failure>, Never> {
            return await performRefresh(refreshToken: refreshToken)
        }

        inFlightTask = task

        let result = await task.value
        inFlightTask = nil
        return result
    }

    private func performRefresh(refreshToken: String) async -> Result<AuthSession, Failure> {
        let outcome = await refreshTransport.refresh(refreshToken: refreshToken)
        switch outcome {
        case .refreshed(let newSession):
            switch vault.write(newSession) {
            case .success:
                return .success(newSession)
            case .failure(let failure):
                return .failure(failure)
            }
        case .refused, .unknown:
            _ = vault.clear()
            return .failure(.sessionExpired)
        case .notSpent(let failure):
            return .failure(failure)
        }
    }
}
