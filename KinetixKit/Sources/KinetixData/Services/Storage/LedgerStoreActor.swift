import Foundation
import KinetixDomain
import SwiftData

@ModelActor
public actor LedgerStoreActor {
    public func isExecutingOffMainThread() -> Bool {
        return !Thread.isMainThread
    }

    public func fetchOutboxEntry(dedupeKey: String) throws -> OutboxEntrySnapshot? {
        let descriptor = FetchDescriptor<OutboxEntryRecord>(
            predicate: #Predicate<OutboxEntryRecord> { record in
                record.dedupeKey == dedupeKey
            }
        )

        guard let record = try modelContext.fetch(descriptor).first else {
            return nil
        }

        return snapshot(from: record)
    }

    public func upsertMergedOutboxEntry(
        dedupeKey: String,
        principalId: PrincipalId,
        accountId: AccountId,
        operationKind: OutboxOperationKind,
        payloadData: Data,
        now: Date,
    ) throws -> OutboxEntrySnapshot {
        let descriptor = FetchDescriptor<OutboxEntryRecord>(
            predicate: #Predicate<OutboxEntryRecord> { record in
                record.dedupeKey == dedupeKey
            }
        )

        let record: OutboxEntryRecord
        if let existing = try modelContext.fetch(descriptor).first {
            existing.payloadData = payloadData
            existing.statusRaw = OutboxEntryStatus.pending.rawValue
            existing.nextAttemptAt = now
            existing.updatedAt = now
            record = existing
        } else {
            let inserted = OutboxEntryRecord(
                dedupeKey: dedupeKey,
                principalId: principalId.value,
                accountId: accountId.value,
                operationKind: operationKind.rawValue,
                payloadData: payloadData,
                statusRaw: OutboxEntryStatus.pending.rawValue,
                attemptCount: 0,
                nextAttemptAt: now,
                createdAt: now,
                updatedAt: now,
                lastError: nil,
            )
            modelContext.insert(inserted)
            record = inserted
        }

        try modelContext.save()

        guard let snap = snapshot(from: record) else {
            throw CocoaError(.fileWriteUnknown)
        }

        return snap
    }

    public func listReadyOutboxEntries(
        for principalId: PrincipalId,
        now: Date,
    ) throws -> [OutboxEntrySnapshot] {
        let targetPrincipal = principalId.value
        let pendingRaw = OutboxEntryStatus.pending.rawValue
        let inFlightRaw = OutboxEntryStatus.inFlight.rawValue
        let descriptor = FetchDescriptor<OutboxEntryRecord>(
            predicate: #Predicate<OutboxEntryRecord> { record in
                record.principalId == targetPrincipal
                    && (record.statusRaw == pendingRaw || record.statusRaw == inFlightRaw)
                    && record.nextAttemptAt <= now
            },
            sortBy: [SortDescriptor(\OutboxEntryRecord.createdAt, order: .forward)],
        )

        let records = try modelContext.fetch(descriptor)
        return records.compactMap { snapshot(from: $0) }
    }

    public func hasPendingOutboxEntries(for principalId: PrincipalId) throws -> Bool {
        let targetPrincipal = principalId.value
        let pendingRaw = OutboxEntryStatus.pending.rawValue
        let inFlightRaw = OutboxEntryStatus.inFlight.rawValue
        let descriptor = FetchDescriptor<OutboxEntryRecord>(
            predicate: #Predicate<OutboxEntryRecord> { record in
                record.principalId == targetPrincipal
                    && (record.statusRaw == pendingRaw || record.statusRaw == inFlightRaw)
            }
        )

        let count = try modelContext.fetchCount(descriptor)
        return count > 0
    }

    public func markInFlight(
        dedupeKey: String,
        now: Date,
    ) throws {
        guard let record = try fetchRecord(dedupeKey: dedupeKey) else {
            return
        }

        record.statusRaw = OutboxEntryStatus.inFlight.rawValue
        record.updatedAt = now
        try modelContext.save()
    }

    public func markRetryLater(
        dedupeKey: String,
        attemptCount: Int,
        nextAttemptAt: Date,
        lastError: String,
        now: Date,
    ) throws {
        guard let record = try fetchRecord(dedupeKey: dedupeKey) else {
            return
        }

        record.statusRaw = OutboxEntryStatus.pending.rawValue
        record.attemptCount = attemptCount
        record.nextAttemptAt = nextAttemptAt
        record.lastError = lastError
        record.updatedAt = now
        try modelContext.save()
    }

    public func markPermanentFailure(
        dedupeKey: String,
        attemptCount: Int,
        lastError: String,
        now: Date,
    ) throws {
        guard let record = try fetchRecord(dedupeKey: dedupeKey) else {
            return
        }

        record.statusRaw = OutboxEntryStatus.failed.rawValue
        record.attemptCount = attemptCount
        record.lastError = lastError
        record.updatedAt = now
        try modelContext.save()
    }

    public func removeOutboxEntry(dedupeKey: String) throws {
        guard let record = try fetchRecord(dedupeKey: dedupeKey) else {
            return
        }

        modelContext.delete(record)
        try modelContext.save()
    }

    private func fetchRecord(dedupeKey: String) throws -> OutboxEntryRecord? {
        let descriptor = FetchDescriptor<OutboxEntryRecord>(
            predicate: #Predicate<OutboxEntryRecord> { record in
                record.dedupeKey == dedupeKey
            }
        )
        return try modelContext.fetch(descriptor).first
    }

    private func snapshot(from record: OutboxEntryRecord) -> OutboxEntrySnapshot? {
        guard
            let principalId = PrincipalId(record.principalId),
            let accountId = AccountId(record.accountId),
            let kind = OutboxOperationKind(rawValue: record.operationKind),
            let status = OutboxEntryStatus(rawValue: record.statusRaw)
        else {
            return nil
        }

        return OutboxEntrySnapshot(
            dedupeKey: record.dedupeKey,
            principalId: principalId,
            accountId: accountId,
            operationKind: kind,
            payloadData: record.payloadData,
            status: status,
            attemptCount: record.attemptCount,
            nextAttemptAt: record.nextAttemptAt,
            createdAt: record.createdAt,
            updatedAt: record.updatedAt,
            lastError: record.lastError,
        )
    }
}
