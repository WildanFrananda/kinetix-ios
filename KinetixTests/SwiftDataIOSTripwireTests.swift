import Foundation
import KinetixData
import KinetixDomain
import SwiftData
import Testing

struct SwiftDataIOSTripwireTests {
    @Test
    func ledgerPersistsAcrossContainersPreservesUpsertStateAndRunsOffMainThreadOnIOS() async throws
    {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("kinetix-ios-tripwire-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: dir) }

        let storeURL = dir.appendingPathComponent("ledger.store")
        let principal = try #require(PrincipalId("0f8b6c1e-5a2d-4c3b-9e7f-1a2b3c4d5e6f"))
        let account = try #require(AccountId(42))
        let now = Date(timeIntervalSince1970: 1_760_000_000)
        let key = "profile:\(principal.value)"

        let firstContainer = try SwiftDataLedgerContainerFactory(storeURL: storeURL).open()
        let firstActor = LedgerStoreActor(modelContainer: firstContainer)

        #expect(await firstActor.isExecutingOffMainThread())

        _ = try await firstActor.upsertMergedOutboxEntry(
            dedupeKey: key,
            principalId: principal,
            accountId: account,
            operationKind: .profileUpdate,
            payloadData: Data("ios-first".utf8),
            now: now,
        )
        try await firstActor.markRetryLater(
            dedupeKey: key,
            attemptCount: 2,
            nextAttemptAt: now.addingTimeInterval(30),
            lastError: "networkNotSent",
            now: now,
        )
        _ = try await firstActor.upsertMergedOutboxEntry(
            dedupeKey: key,
            principalId: principal,
            accountId: account,
            operationKind: .profileUpdate,
            payloadData: Data("ios-merged".utf8),
            now: now.addingTimeInterval(5),
        )

        let secondContainer = try SwiftDataLedgerContainerFactory(storeURL: storeURL).open()
        let secondActor = LedgerStoreActor(modelContainer: secondContainer)
        let reloaded = try await secondActor.fetchOutboxEntry(dedupeKey: key)

        #expect(reloaded?.payloadData == Data("ios-merged".utf8))
        #expect(reloaded?.attemptCount == 2)
    }
}
