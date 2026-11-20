import Foundation
import KinetixDomain

public struct ProfileOutboxExecutor: OutboxExecutor {
    private let apiClient: IdentityAPIClient
    private let cacheStore: any ProfileCacheStore
    private let clock: any AppClock

    public init(
        apiClient: IdentityAPIClient,
        cacheStore: any ProfileCacheStore,
        clock: any AppClock,
    ) {
        self.apiClient = apiClient
        self.cacheStore = cacheStore
        self.clock = clock
    }

    public func execute(_ entry: OutboxEntrySnapshot) async -> Result<Void, Failure> {
        guard entry.operationKind == .profileUpdate else {
            return .failure(.validation(ValidationFailure()))
        }

        guard let patch = try? JSONDecoder().decode(ProfilePatch.self, from: entry.payloadData)
        else {
            return .failure(.validation(ValidationFailure()))
        }

        let result = await apiClient.updateProfile(accountId: entry.accountId, patch: patch)
        switch result {
        case .success(let profile):
            _ = await cacheStore.saveProfile(
                profile,
                principalId: entry.principalId,
                savedAt: clock.now(),
            )
            return .success(())
        case .failure(.conflict):
            if case .success(let existing) = await apiClient.fetchProfile(
                accountId: entry.accountId
            ) {
                _ = await cacheStore.saveProfile(
                    existing,
                    principalId: entry.principalId,
                    savedAt: clock.now(),
                )
            }

            let retry = await apiClient.updateProfile(accountId: entry.accountId, patch: patch)
            switch retry {
            case .success(let profile):
                _ = await cacheStore.saveProfile(
                    profile,
                    principalId: entry.principalId,
                    savedAt: clock.now(),
                )
                return .success(())
            case .failure(let failure):
                return .failure(failure)
            }
        case .failure(.outcomeUnknown):
            let readResult = await apiClient.fetchProfile(accountId: entry.accountId)
            if case .success(let fetched) = readResult {
                _ = await cacheStore.saveProfile(
                    fetched,
                    principalId: entry.principalId,
                    savedAt: clock.now(),
                )
                if Self.profileMatchesPatch(fetched, patch: patch) {
                    return .success(())
                }
            }

            return .failure(.outcomeUnknown)
        case .failure(let failure):
            return .failure(failure)
        }
    }

    public static func profileMatchesPatch(
        _ profile: DeliveryProfile,
        patch: ProfilePatch,
    ) -> Bool {
        if let fullName = patch.fullName, profile.fullName != fullName {
            return false
        }

        if let phoneNumber = patch.phoneNumber, profile.phoneNumber != phoneNumber {
            return false
        }

        if let streetAddress = patch.streetAddress, profile.streetAddress != streetAddress {
            return false
        }

        if let city = patch.city, profile.city != city {
            return false
        }

        if let postalCode = patch.postalCode, profile.postalCode != postalCode {
            return false
        }

        switch patch.avatarUpdate {
        case .unchanged:
            return true
        case .set(let expected):
            return profile.avatarURL == expected
        case .remove:
            return profile.avatarURL == nil
        }
    }
}
