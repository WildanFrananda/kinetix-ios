import Foundation
import KinetixDomain

public protocol OutboxStore: Sendable {
    func fetchEntry(dedupeKey: String) async -> Result<OutboxEntrySnapshot?, Failure>

    func upsertMergedEntry(
        dedupeKey: String,
        principalId: PrincipalId,
        accountId: AccountId,
        operationKind: OutboxOperationKind,
        payloadData: Data,
        now: Date,
    ) async -> Result<OutboxEntrySnapshot, Failure>

    func listReadyEntries(
        for principalId: PrincipalId,
        now: Date,
    ) async -> Result<[OutboxEntrySnapshot], Failure>

    func hasPendingEntries(for principalId: PrincipalId) async -> Result<Bool, Failure>

    func markInFlight(
        dedupeKey: String,
        now: Date,
    ) async -> Result<Void, Failure>

    func markRetryLater(
        dedupeKey: String,
        attemptCount: Int,
        nextAttemptAt: Date,
        lastError: String,
        now: Date,
    ) async -> Result<Void, Failure>

    func markPermanentFailure(
        dedupeKey: String,
        attemptCount: Int,
        lastError: String,
        now: Date,
    ) async -> Result<Void, Failure>

    func removeEntry(dedupeKey: String) async -> Result<Void, Failure>
}
