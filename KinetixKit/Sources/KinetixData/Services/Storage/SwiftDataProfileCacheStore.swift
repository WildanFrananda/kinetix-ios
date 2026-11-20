import Foundation
import KinetixDomain
import SwiftData

public actor SwiftDataProfileCacheStore: ProfileCacheStore {
    private let factory: SwiftDataCacheContainerFactory
    private let protectedDataProvider: any ProtectedDataStatusProvider
    private var storeActor: CacheStoreActor?

    public init(
        factory: SwiftDataCacheContainerFactory = SwiftDataCacheContainerFactory(),
        protectedDataProvider: any ProtectedDataStatusProvider,
    ) {
        self.factory = factory
        self.protectedDataProvider = protectedDataProvider
    }

    public func readProfile(
        accountId: AccountId,
        principalId: PrincipalId,
    ) async -> Result<DeliveryProfile?, Failure> {
        switch resolveActor() {
        case .failure(let failure):
            return .failure(failure)
        case .success(let actor):
            do {
                let profile = try await actor.readProfile(
                    accountId: accountId,
                    principalId: principalId,
                )
                return .success(profile)
            } catch {
                return .failure(.serviceUnavailable)
            }
        }
    }

    public func saveProfile(
        _ profile: DeliveryProfile,
        principalId: PrincipalId,
        savedAt: Date,
    ) async -> Result<Void, Failure> {
        switch resolveActor() {
        case .failure(let failure):
            return .failure(failure)
        case .success(let actor):
            do {
                try await actor.saveProfile(
                    profile,
                    principalId: principalId,
                    savedAt: savedAt,
                )
                return .success(())
            } catch {
                return .failure(.serviceUnavailable)
            }
        }
    }

    public func clearProfile(for principalId: PrincipalId) async -> Result<Void, Failure> {
        switch resolveActor() {
        case .failure(let failure):
            return .failure(failure)
        case .success(let actor):
            do {
                try await actor.clearProfile(for: principalId)
                return .success(())
            } catch {
                return .failure(.serviceUnavailable)
            }
        }
    }

    private func resolveActor() -> Result<CacheStoreActor, Failure> {
        guard protectedDataProvider.isProtectedDataAvailable() else {
            return .failure(.sessionUnavailable)
        }

        if let storeActor {
            return .success(storeActor)
        }

        do {
            let container = try factory.openOrRebuild()
            let actor = CacheStoreActor(modelContainer: container)
            storeActor = actor
            return .success(actor)
        } catch {
            return .failure(.serviceUnavailable)
        }
    }
}
