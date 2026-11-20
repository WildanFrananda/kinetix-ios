import Foundation
import KinetixDomain

public actor OutboxProcessor {
    private let outboxStore: any OutboxStore
    private let executor: any OutboxExecutor
    private let clock: any AppClock
    private let analyticsTracker: any AnalyticsTracker
    private let crashReporter: any CrashReporter
    private var isDraining = false

    public init(
        outboxStore: any OutboxStore,
        executor: any OutboxExecutor,
        clock: any AppClock,
        analyticsTracker: any AnalyticsTracker,
        crashReporter: any CrashReporter,
    ) {
        self.outboxStore = outboxStore
        self.executor = executor
        self.clock = clock
        self.analyticsTracker = analyticsTracker
        self.crashReporter = crashReporter
    }

    public static func profileDedupeKey(for principalId: PrincipalId) -> String {
        return "profile:\(principalId.value)"
    }

    public func enqueueProfilePatch(
        _ patch: ProfilePatch,
        accountId: AccountId,
        principalId: PrincipalId,
    ) async -> Result<ProfilePatch, Failure> {
        let dedupeKey = Self.profileDedupeKey(for: principalId)
        let mergedPatch: ProfilePatch

        switch await outboxStore.fetchEntry(dedupeKey: dedupeKey) {
        case .failure(let failure):
            return .failure(failure)
        case .success(let existing):
            if let existing,
                existing.principalId == principalId,
                let previousPatch = try? JSONDecoder().decode(
                    ProfilePatch.self,
                    from: existing.payloadData,
                )
            {
                mergedPatch = previousPatch.merged(with: patch)
            } else {
                mergedPatch = patch
            }
        }

        guard let encoded = try? JSONEncoder().encode(mergedPatch) else {
            return .failure(.ledgerUnavailable)
        }

        let upsertResult = await outboxStore.upsertMergedEntry(
            dedupeKey: dedupeKey,
            principalId: principalId,
            accountId: accountId,
            operationKind: .profileUpdate,
            payloadData: encoded,
            now: clock.now(),
        )
        switch upsertResult {
        case .success:
            return .success(mergedPatch)
        case .failure(let failure):
            return .failure(failure)
        }
    }

    public func pendingProfilePatch(
        for principalId: PrincipalId
    ) async -> Result<ProfilePatch?, Failure> {
        let dedupeKey = Self.profileDedupeKey(for: principalId)
        switch await outboxStore.fetchEntry(dedupeKey: dedupeKey) {
        case .failure(let failure):
            return .failure(failure)
        case .success(let entry):
            guard
                let entry,
                entry.principalId == principalId,
                entry.status != .failed,
                let patch = try? JSONDecoder().decode(ProfilePatch.self, from: entry.payloadData)
            else {
                return .success(nil)
            }

            return .success(patch)
        }
    }

    public func hasPendingEntries(for principalId: PrincipalId) async -> Bool {
        switch await outboxStore.hasPendingEntries(for: principalId) {
        case .success(let hasPending):
            return hasPending
        case .failure:
            return false
        }
    }

    public func drain(for activePrincipalId: PrincipalId) async -> Result<
        OutboxDrainResult, Failure
    > {
        guard !isDraining else {
            return .success(
                OutboxDrainResult(
                    syncedCount: 0,
                    retryLaterCount: 0,
                    permanentFailureCount: 0,
                )
            )
        }

        isDraining = true
        defer { isDraining = false }

        let now = clock.now()
        let entries: [OutboxEntrySnapshot]
        switch await outboxStore.listReadyEntries(for: activePrincipalId, now: now) {
        case .failure(let failure):
            return .failure(failure)
        case .success(let loaded):
            entries = loaded
        }

        var synced = 0
        var retryLater = 0
        var permanentFailures = 0

        for entry in entries {
            guard entry.principalId == activePrincipalId else {
                continue
            }

            _ = await outboxStore.markInFlight(dedupeKey: entry.dedupeKey, now: clock.now())
            let execution = await executor.execute(entry)

            switch execution {
            case .success:
                _ = await outboxStore.removeEntry(dedupeKey: entry.dedupeKey)
                analyticsTracker.logEvent(
                    name: "outbox_entry_synced",
                    params: ["operation": entry.operationKind.rawValue],
                )
                synced += 1
            case .failure(let failure):
                if failure == .cancelled {
                    _ = await outboxStore.markRetryLater(
                        dedupeKey: entry.dedupeKey,
                        attemptCount: entry.attemptCount,
                        nextAttemptAt: clock.now(),
                        lastError: "cancelled",
                        now: clock.now(),
                    )
                    continue
                }

                let nextAttempt = entry.attemptCount + 1
                let errorName = String(describing: failure)
                let shouldRetry = OutboxBackoffPolicy.isRetryable(
                    failure: failure,
                    operationKind: entry.operationKind,
                )

                if shouldRetry {
                    let delay = OutboxBackoffPolicy.delaySeconds(
                        forAttempt: nextAttempt,
                        failure: failure,
                    )
                    let nextDate = clock.now().addingTimeInterval(TimeInterval(delay))
                    _ = await outboxStore.markRetryLater(
                        dedupeKey: entry.dedupeKey,
                        attemptCount: nextAttempt,
                        nextAttemptAt: nextDate,
                        lastError: errorName,
                        now: clock.now(),
                    )
                    retryLater += 1
                } else {
                    _ = await outboxStore.markPermanentFailure(
                        dedupeKey: entry.dedupeKey,
                        attemptCount: nextAttempt,
                        lastError: errorName,
                        now: clock.now(),
                    )
                    crashReporter.recordNonFatal(
                        code: "outbox_permanent_failure",
                        context: [
                            "operation": entry.operationKind.rawValue,
                            "attempt": String(nextAttempt),
                        ],
                    )
                    permanentFailures += 1
                }
            }
        }

        return .success(
            OutboxDrainResult(
                syncedCount: synced,
                retryLaterCount: retryLater,
                permanentFailureCount: permanentFailures,
            )
        )
    }
}
