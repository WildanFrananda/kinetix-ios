import Foundation
import KinetixDomain

public protocol ProfileCacheStore: Sendable {
    func readProfile(
        accountId: AccountId,
        principalId: PrincipalId,
    ) async -> Result<DeliveryProfile?, Failure>

    func saveProfile(
        _ profile: DeliveryProfile,
        principalId: PrincipalId,
        savedAt: Date,
    ) async -> Result<Void, Failure>

    func clearProfile(for principalId: PrincipalId) async -> Result<Void, Failure>
}
