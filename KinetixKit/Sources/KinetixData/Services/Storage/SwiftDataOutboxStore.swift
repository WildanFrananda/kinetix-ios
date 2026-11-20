import Foundation
import KinetixDomain
import SwiftData

public actor SwiftDataOutboxStore: OutboxStore {
    private let factory: SwiftDataLedgerContainerFactory
    private let protectedDataProvider: any ProtectedDataStatusProvider
    private let crashReporter: any CrashReporter
    private var storeActor: LedgerStoreActor?

    public init(
        factory: SwiftDataLedgerContainerFactory = SwiftDataLedgerContainerFactory(),
        protectedDataProvider: any ProtectedDataStatusProvider,
        crashReporter: any CrashReporter,
    ) {
        self.factory = factory
        self.protectedDataProvider = protectedDataProvider
        self.crashReporter = crashReporter
    }

    public func fetchEntry(dedupeKey: String) async -> Result<OutboxEntrySnapshot?, Failure> {
        switch resolveActor() {
        case .failure(let failure):
            return .failure(failure)
        case .success(let actor):
            do {
                return .success(try await actor.fetchOutboxEntry(dedupeKey: dedupeKey))
            } catch {
                return .failure(.ledgerUnavailable)
            }
        }
    }

    public func upsertMergedEntry(
        dedupeKey: String,
        principalId: PrincipalId,
        accountId: AccountId,
        operationKind: OutboxOperationKind,
        payloadData: Data,
        now: Date,
    ) async -> Result<OutboxEntrySnapshot, Failure> {
        switch resolveActor() {
        case .failure(let failure):
            return .failure(failure)
        case .success(let actor):
            do {
                let snapshot = try await actor.upsertMergedOutboxEntry(
                    dedupeKey: dedupeKey,
                    principalId: principalId,
                    accountId: accountId,
                    operationKind: operationKind,
                    payloadData: payloadData,
                    now: now,
                )
                return .success(snapshot)
            } catch {
                return .failure(.ledgerUnavailable)
            }
        }
    }

    public func listReadyEntries(
        for principalId: PrincipalId,
        now: Date,
    ) async -> Result<[OutboxEntrySnapshot], Failure> {
        switch resolveActor() {
        case .failure(let failure):
            return .failure(failure)
        case .success(let actor):
            do {
                let entries = try await actor.listReadyOutboxEntries(
                    for: principalId,
                    now: now,
                )
                return .success(entries)
            } catch {
                return .failure(.ledgerUnavailable)
            }
        }
    }

    public func hasPendingEntries(for principalId: PrincipalId) async -> Result<Bool, Failure> {
        switch resolveActor() {
        case .failure(let failure):
            return .failure(failure)
        case .success(let actor):
            do {
                return .success(try await actor.hasPendingOutboxEntries(for: principalId))
            } catch {
                return .failure(.ledgerUnavailable)
            }
        }
    }

    public func markInFlight(
        dedupeKey: String,
        now: Date,
    ) async -> Result<Void, Failure> {
        switch resolveActor() {
        case .failure(let failure):
            return .failure(failure)
        case .success(let actor):
            do {
                try await actor.markInFlight(dedupeKey: dedupeKey, now: now)
                return .success(())
            } catch {
                return .failure(.ledgerUnavailable)
            }
        }
    }

    public func markRetryLater(
        dedupeKey: String,
        attemptCount: Int,
        nextAttemptAt: Date,
        lastError: String,
        now: Date,
    ) async -> Result<Void, Failure> {
        switch resolveActor() {
        case .failure(let failure):
            return .failure(failure)
        case .success(let actor):
            do {
                try await actor.markRetryLater(
                    dedupeKey: dedupeKey,
                    attemptCount: attemptCount,
                    nextAttemptAt: nextAttemptAt,
                    lastError: lastError,
                    now: now,
                )
                return .success(())
            } catch {
                return .failure(.ledgerUnavailable)
            }
        }
    }

    public func markPermanentFailure(
        dedupeKey: String,
        attemptCount: Int,
        lastError: String,
        now: Date,
    ) async -> Result<Void, Failure> {
        switch resolveActor() {
        case .failure(let failure):
            return .failure(failure)
        case .success(let actor):
            do {
                try await actor.markPermanentFailure(
                    dedupeKey: dedupeKey,
                    attemptCount: attemptCount,
                    lastError: lastError,
                    now: now,
                )
                return .success(())
            } catch {
                return .failure(.ledgerUnavailable)
            }
        }
    }

    public func removeEntry(dedupeKey: String) async -> Result<Void, Failure> {
        switch resolveActor() {
        case .failure(let failure):
            return .failure(failure)
        case .success(let actor):
            do {
                try await actor.removeOutboxEntry(dedupeKey: dedupeKey)
                return .success(())
            } catch {
                return .failure(.ledgerUnavailable)
            }
        }
    }

    private func resolveActor() -> Result<LedgerStoreActor, Failure> {
        guard protectedDataProvider.isProtectedDataAvailable() else {
            return .failure(.sessionUnavailable)
        }

        if let storeActor {
            return .success(storeActor)
        }

        do {
            let container = try factory.open()
            let actor = LedgerStoreActor(modelContainer: container)
            storeActor = actor
            return .success(actor)
        } catch {
            crashReporter.recordNonFatal(
                code: "ledger_open_failed",
                context: ["store": "ledger"],
            )
            return .failure(.ledgerUnavailable)
        }
    }
}
