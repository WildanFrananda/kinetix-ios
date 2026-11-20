import Foundation
import KinetixDomain

public struct FirstLaunchSessionCleaner: Sendable {
    private let vault: any SessionVault
    private let markerStore: any FirstLaunchMarkerStore
    private let protectedDataProvider: any ProtectedDataStatusProvider

    public init(
        vault: any SessionVault,
        markerStore: any FirstLaunchMarkerStore,
        protectedDataProvider: any ProtectedDataStatusProvider,
    ) {
        self.vault = vault
        self.markerStore = markerStore
        self.protectedDataProvider = protectedDataProvider
    }

    public func runOnForegroundActivation() -> Result<Void, Failure> {
        guard protectedDataProvider.isProtectedDataAvailable() else {
            return .failure(.sessionUnavailable)
        }

        if markerStore.hasCompletedFirstLaunch() {
            return .success(())
        }

        switch vault.clear() {
        case .success:
            markerStore.markFirstLaunchCompleted()
            return .success(())
        case .failure(let failure):
            return .failure(failure)
        }
    }
}
