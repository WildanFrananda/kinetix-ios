import Foundation
import KinetixData
import KinetixDomain
import Synchronization

public final class FakeProfileCacheStore: ProfileCacheStore {
    private let storage = Mutex<[AccountId: (principalId: PrincipalId, profile: DeliveryProfile)]>(
        [:]
    )

    public init() {}

    public func readProfile(
        accountId: AccountId,
        principalId: PrincipalId,
    ) async -> Result<DeliveryProfile?, Failure> {
        let found = storage.withLock { map -> DeliveryProfile? in
            guard let item = map[accountId], item.principalId == principalId else {
                return nil
            }

            return item.profile
        }

        return .success(found)
    }

    public func saveProfile(
        _ profile: DeliveryProfile,
        principalId: PrincipalId,
        savedAt: Date,
    ) async -> Result<Void, Failure> {
        storage.withLock { $0[profile.accountId] = (principalId: principalId, profile: profile) }
        return .success(())
    }

    public func clearProfile(for principalId: PrincipalId) async -> Result<Void, Failure> {
        storage.withLock { map in
            map = map.filter { $0.value.principalId != principalId }
        }

        return .success(())
    }
}
