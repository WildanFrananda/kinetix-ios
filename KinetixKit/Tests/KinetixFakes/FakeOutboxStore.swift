import Foundation
import KinetixData
import KinetixDomain
import Synchronization

public final class FakeOutboxStore: OutboxStore {
    private let entries = Mutex<[String: OutboxEntrySnapshot]>([:])

    public init() {}

    public func fetchEntry(dedupeKey: String) async -> Result<OutboxEntrySnapshot?, Failure> {
        return .success(entries.withLock { $0[dedupeKey] })
    }

    public func upsertMergedEntry(
        dedupeKey: String,
        principalId: PrincipalId,
        accountId: AccountId,
        operationKind: OutboxOperationKind,
        payloadData: Data,
        now: Date,
    ) async -> Result<OutboxEntrySnapshot, Failure> {
        let snap = entries.withLock { map -> OutboxEntrySnapshot in
            let existing = map[dedupeKey]
            let updated = OutboxEntrySnapshot(
                dedupeKey: dedupeKey,
                principalId: principalId,
                accountId: accountId,
                operationKind: operationKind,
                payloadData: payloadData,
                status: .pending,
                attemptCount: existing?.attemptCount ?? 0,
                nextAttemptAt: now,
                createdAt: existing?.createdAt ?? now,
                updatedAt: now,
                lastError: existing?.lastError,
            )
            map[dedupeKey] = updated
            return updated
        }

        return .success(snap)
    }

    public func listReadyEntries(
        for principalId: PrincipalId,
        now: Date,
    ) async -> Result<[OutboxEntrySnapshot], Failure> {
        let ready = entries.withLock { map in
            map.values
                .filter {
                    $0.principalId == principalId
                        && ($0.status == .pending || $0.status == .inFlight)
                        && $0.nextAttemptAt <= now
                }
                .sorted { $0.createdAt < $1.createdAt }
        }

        return .success(ready)
    }

    public func hasPendingEntries(for principalId: PrincipalId) async -> Result<Bool, Failure> {
        let hasAny = entries.withLock { map in
            map.values.contains {
                $0.principalId == principalId && ($0.status == .pending || $0.status == .inFlight)
            }
        }

        return .success(hasAny)
    }

    public func markInFlight(
        dedupeKey: String,
        now: Date,
    ) async -> Result<Void, Failure> {
        entries.withLock { map in
            guard let existing = map[dedupeKey] else {
                return
            }

            map[dedupeKey] = OutboxEntrySnapshot(
                dedupeKey: existing.dedupeKey,
                principalId: existing.principalId,
                accountId: existing.accountId,
                operationKind: existing.operationKind,
                payloadData: existing.payloadData,
                status: .inFlight,
                attemptCount: existing.attemptCount,
                nextAttemptAt: existing.nextAttemptAt,
                createdAt: existing.createdAt,
                updatedAt: now,
                lastError: existing.lastError,
            )
        }

        return .success(())
    }

    public func markRetryLater(
        dedupeKey: String,
        attemptCount: Int,
        nextAttemptAt: Date,
        lastError: String,
        now: Date,
    ) async -> Result<Void, Failure> {
        entries.withLock { map in
            guard let existing = map[dedupeKey] else {
                return
            }

            map[dedupeKey] = OutboxEntrySnapshot(
                dedupeKey: existing.dedupeKey,
                principalId: existing.principalId,
                accountId: existing.accountId,
                operationKind: existing.operationKind,
                payloadData: existing.payloadData,
                status: .pending,
                attemptCount: attemptCount,
                nextAttemptAt: nextAttemptAt,
                createdAt: existing.createdAt,
                updatedAt: now,
                lastError: lastError,
            )
        }

        return .success(())
    }

    public func markPermanentFailure(
        dedupeKey: String,
        attemptCount: Int,
        lastError: String,
        now: Date,
    ) async -> Result<Void, Failure> {
        entries.withLock { map in
            guard let existing = map[dedupeKey] else {
                return
            }

            map[dedupeKey] = OutboxEntrySnapshot(
                dedupeKey: existing.dedupeKey,
                principalId: existing.principalId,
                accountId: existing.accountId,
                operationKind: existing.operationKind,
                payloadData: existing.payloadData,
                status: .failed,
                attemptCount: attemptCount,
                nextAttemptAt: existing.nextAttemptAt,
                createdAt: existing.createdAt,
                updatedAt: now,
                lastError: lastError,
            )
        }

        return .success(())
    }

    public func removeEntry(dedupeKey: String) async -> Result<Void, Failure> {
        entries.withLock { $0[dedupeKey] = nil }
        return .success(())
    }
}
