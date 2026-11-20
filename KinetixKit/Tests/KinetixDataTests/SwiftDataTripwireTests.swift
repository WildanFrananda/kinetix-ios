import Foundation
import KinetixData
import KinetixDomain
import KinetixFakes
import SwiftData
import Testing

struct SwiftDataTripwireTests {
    @Test
    func ledgerSaveSurvivesReopeningNewModelContainerOnSameFile() async throws {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("kinetix-tripwire-persist-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: dir) }

        let storeURL = dir.appendingPathComponent("ledger.store")
        let principal = try #require(PrincipalId("0f8b6c1e-5a2d-4c3b-9e7f-1a2b3c4d5e6f"))
        let account = try #require(AccountId(42))
        let now = Date(timeIntervalSince1970: 1_760_000_000)

        let firstContainer = try SwiftDataLedgerContainerFactory(storeURL: storeURL).open()
        let firstActor = LedgerStoreActor(modelContainer: firstContainer)
        _ = try await firstActor.upsertMergedOutboxEntry(
            dedupeKey: "profile:\(principal.value)",
            principalId: principal,
            accountId: account,
            operationKind: .profileUpdate,
            payloadData: Data("payload-v1".utf8),
            now: now,
        )

        let secondContainer = try SwiftDataLedgerContainerFactory(storeURL: storeURL).open()
        let secondActor = LedgerStoreActor(modelContainer: secondContainer)
        let reloaded = try await secondActor.fetchOutboxEntry(
            dedupeKey: "profile:\(principal.value)"
        )

        #expect(reloaded?.payloadData == Data("payload-v1".utf8))
        #expect(reloaded?.principalId == principal)
    }

    @Test
    func uniqueUpsertPreservesAttemptCountWhenUpdatingExistingOutboxEntry() async throws {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("kinetix-tripwire-unique-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: dir) }

        let storeURL = dir.appendingPathComponent("ledger.store")
        let principal = try #require(PrincipalId("0f8b6c1e-5a2d-4c3b-9e7f-1a2b3c4d5e6f"))
        let account = try #require(AccountId(42))
        let now = Date(timeIntervalSince1970: 1_760_000_000)

        let container = try SwiftDataLedgerContainerFactory(storeURL: storeURL).open()
        let actor = LedgerStoreActor(modelContainer: container)
        let key = "profile:\(principal.value)"

        _ = try await actor.upsertMergedOutboxEntry(
            dedupeKey: key,
            principalId: principal,
            accountId: account,
            operationKind: .profileUpdate,
            payloadData: Data("first".utf8),
            now: now,
        )
        try await actor.markRetryLater(
            dedupeKey: key,
            attemptCount: 3,
            nextAttemptAt: now.addingTimeInterval(60),
            lastError: "serviceUnavailable",
            now: now,
        )

        let updated = try await actor.upsertMergedOutboxEntry(
            dedupeKey: key,
            principalId: principal,
            accountId: account,
            operationKind: .profileUpdate,
            payloadData: Data("second".utf8),
            now: now.addingTimeInterval(5),
        )

        #expect(updated.attemptCount == 3)
        #expect(updated.payloadData == Data("second".utf8))
    }

    @Test
    func lightweightMigrationBetweenNestedSchemaVersionsPreservesRows() throws {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("kinetix-tripwire-migration-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: dir) }

        let storeURL = dir.appendingPathComponent("migration.store")

        let v1Schema = Schema(versionedSchema: TripwireLedgerV1.self)
        let v1Config = ModelConfiguration(
            "MigrationTripwire",
            schema: v1Schema,
            url: storeURL,
            cloudKitDatabase: .none,
        )
        let v1Container = try ModelContainer(for: v1Schema, configurations: [v1Config])
        let v1Context = ModelContext(v1Container)
        v1Context.insert(TripwireLedgerV1.TripwireRow(key: "row-1", payload: "keep-me"))
        try v1Context.save()

        let v2Schema = Schema(versionedSchema: TripwireLedgerV2.self)
        let v2Config = ModelConfiguration(
            "MigrationTripwire",
            schema: v2Schema,
            url: storeURL,
            cloudKitDatabase: .none,
        )
        let v2Container = try ModelContainer(
            for: v2Schema,
            migrationPlan: TripwireLedgerMigrationPlan.self,
            configurations: [v2Config],
        )
        let v2Context = ModelContext(v2Container)
        let rows = try v2Context.fetch(FetchDescriptor<TripwireLedgerV2.TripwireRow>())

        #expect(rows.count == 1)
        #expect(rows.first?.key == "row-1")
        #expect(rows.first?.payload == "keep-me")
    }

    @Test
    func storeActorsExecuteOffMainThread() async throws {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("kinetix-tripwire-thread-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: dir) }

        let ledgerURL = dir.appendingPathComponent("ledger.store")
        let cacheURL = dir.appendingPathComponent("cache.store")

        let ledgerActor = LedgerStoreActor(
            modelContainer: try SwiftDataLedgerContainerFactory(storeURL: ledgerURL).open()
        )
        let cacheActor = CacheStoreActor(
            modelContainer: try SwiftDataCacheContainerFactory(storeURL: cacheURL).openOrRebuild()
        )

        #expect(await ledgerActor.isExecutingOffMainThread())
        #expect(await cacheActor.isExecutingOffMainThread())
    }
}
