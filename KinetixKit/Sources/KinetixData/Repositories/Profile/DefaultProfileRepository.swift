import Foundation
import KinetixDomain

public struct DefaultProfileRepository: ProfileRepository {
    private let apiClient: IdentityAPIClient
    private let cacheStore: any ProfileCacheStore
    private let outboxProcessor: OutboxProcessor
    private let outboxStore: any OutboxStore
    private let clock: any AppClock

    public init(
        apiClient: IdentityAPIClient,
        cacheStore: any ProfileCacheStore,
        outboxProcessor: OutboxProcessor,
        outboxStore: any OutboxStore,
        clock: any AppClock,
    ) {
        self.apiClient = apiClient
        self.cacheStore = cacheStore
        self.outboxProcessor = outboxProcessor
        self.outboxStore = outboxStore
        self.clock = clock
    }

    public func fetchProfile(
        accountId: AccountId,
        principalId: PrincipalId,
    ) async -> Result<ProfileFetchOutcome, Failure> {
        let pendingPatch: ProfilePatch?
        if case .success(let loaded) = await outboxProcessor.pendingProfilePatch(for: principalId) {
            pendingPatch = loaded
        } else {
            pendingPatch = nil
        }

        let remoteResult = await apiClient.fetchProfile(accountId: accountId)
        switch remoteResult {
        case .success(let confirmed):
            _ = await cacheStore.saveProfile(
                confirmed,
                principalId: principalId,
                savedAt: clock.now(),
            )
            if let pendingPatch {
                let merged = pendingPatch.applied(to: confirmed, accountId: accountId)
                return .success(.pendingLocalSync(merged))
            }

            return .success(.confirmed(confirmed))
        case .failure(.notFound):
            if let pendingPatch {
                let pendingProfile = pendingPatch.applied(to: nil, accountId: accountId)
                return .success(.pendingLocalSync(pendingProfile))
            }

            return .success(.notCreated)
        case .failure(let failure):
            if Self.isTransientFailure(failure) {
                let cached = await readCached(accountId: accountId, principalId: principalId)
                if let pendingPatch {
                    let pendingProfile = pendingPatch.applied(to: cached, accountId: accountId)
                    return .success(.pendingLocalSync(pendingProfile))
                }

                if let cached {
                    return .success(.cachedStale(cached))
                }
            }

            return .failure(failure)
        }
    }

    public func saveProfile(
        accountId: AccountId,
        principalId: PrincipalId,
        draft: ProfileDraft,
    ) async -> Result<ProfileSaveOutcome, Failure> {
        let confirmed = await readCached(accountId: accountId, principalId: principalId)
        let patch = ProfilePatch.diff(from: confirmed, to: draft)

        if patch.isEmpty {
            if let confirmed {
                return .success(.confirmed(confirmed))
            }

            return .failure(.validation(ValidationFailure()))
        }

        let putResult = await apiClient.updateProfile(accountId: accountId, patch: patch)
        switch putResult {
        case .success(let saved):
            return await finishConfirmedSave(saved, principalId: principalId)
        case .failure(.conflict):
            return await handleConcurrentCreation(
                accountId: accountId,
                principalId: principalId,
                draft: draft,
            )
        case .failure(.outcomeUnknown):
            return await settleUnknownOutcome(
                accountId: accountId,
                principalId: principalId,
                confirmed: confirmed,
                patch: patch,
            )
        case .failure(let failure):
            if Self.isTransientFailure(failure) {
                return await enqueueOffline(
                    patch: patch,
                    confirmed: confirmed,
                    accountId: accountId,
                    principalId: principalId,
                )
            }

            return .failure(failure)
        }
    }

    private func handleConcurrentCreation(
        accountId: AccountId,
        principalId: PrincipalId,
        draft: ProfileDraft,
    ) async -> Result<ProfileSaveOutcome, Failure> {
        let readResult = await apiClient.fetchProfile(accountId: accountId)
        guard case .success(let latestConfirmed) = readResult else {
            if case .failure(let failure) = readResult {
                return .failure(failure)
            }

            return .failure(.outcomeUnknown)
        }

        _ = await cacheStore.saveProfile(
            latestConfirmed,
            principalId: principalId,
            savedAt: clock.now(),
        )

        let recomputedPatch = ProfilePatch.diff(from: latestConfirmed, to: draft)
        if recomputedPatch.isEmpty {
            return await finishConfirmedSave(latestConfirmed, principalId: principalId)
        }

        switch await apiClient.updateProfile(accountId: accountId, patch: recomputedPatch) {
        case .success(let saved):
            return await finishConfirmedSave(saved, principalId: principalId)
        case .failure(let failure):
            if Self.isTransientFailure(failure) {
                return await enqueueOffline(
                    patch: recomputedPatch,
                    confirmed: latestConfirmed,
                    accountId: accountId,
                    principalId: principalId,
                )
            }

            return .failure(failure)
        }
    }

    private func settleUnknownOutcome(
        accountId: AccountId,
        principalId: PrincipalId,
        confirmed: DeliveryProfile?,
        patch: ProfilePatch,
    ) async -> Result<ProfileSaveOutcome, Failure> {
        if case .success(let fetched) = await apiClient.fetchProfile(accountId: accountId) {
            _ = await cacheStore.saveProfile(
                fetched,
                principalId: principalId,
                savedAt: clock.now(),
            )
            if ProfileOutboxExecutor.profileMatchesPatch(fetched, patch: patch) {
                return await finishConfirmedSave(fetched, principalId: principalId)
            }

            return await enqueueOffline(
                patch: patch,
                confirmed: fetched,
                accountId: accountId,
                principalId: principalId,
            )
        }

        return await enqueueOffline(
            patch: patch,
            confirmed: confirmed,
            accountId: accountId,
            principalId: principalId,
        )
    }

    private func finishConfirmedSave(
        _ profile: DeliveryProfile,
        principalId: PrincipalId,
    ) async -> Result<ProfileSaveOutcome, Failure> {
        _ = await cacheStore.saveProfile(
            profile,
            principalId: principalId,
            savedAt: clock.now(),
        )
        let dedupeKey = OutboxProcessor.profileDedupeKey(for: principalId)
        _ = await outboxStore.removeEntry(dedupeKey: dedupeKey)
        return .success(.confirmed(profile))
    }

    private func enqueueOffline(
        patch: ProfilePatch,
        confirmed: DeliveryProfile?,
        accountId: AccountId,
        principalId: PrincipalId,
    ) async -> Result<ProfileSaveOutcome, Failure> {
        let enqueueResult = await outboxProcessor.enqueueProfilePatch(
            patch,
            accountId: accountId,
            principalId: principalId,
        )
        switch enqueueResult {
        case .success(let mergedPatch):
            let pendingProfile = mergedPatch.applied(to: confirmed, accountId: accountId)
            return .success(.queuedOffline(pendingProfile))
        case .failure(let failure):
            return .failure(failure)
        }
    }

    private func readCached(
        accountId: AccountId,
        principalId: PrincipalId,
    ) async -> DeliveryProfile? {
        if case .success(let cached) = await cacheStore.readProfile(
            accountId: accountId,
            principalId: principalId,
        ) {
            return cached
        }

        return nil
    }

    private static func isTransientFailure(_ failure: Failure) -> Bool {
        switch failure {
        case .networkNotSent, .outcomeUnknown, .serviceUnavailable, .rateLimited, .server:
            return true
        case .sessionExpired, .unauthorized, .forbidden, .notFound, .conflict, .validation,
            .unprocessable, .unsupportedAccountRole, .sessionUnavailable, .ledgerUnavailable,
            .unreadableResponse, .cancelled:
            return false
        }
    }
}
