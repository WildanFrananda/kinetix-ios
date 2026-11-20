import Foundation
import KinetixDomain
import SwiftData

public struct SwiftDataLedgerContainerFactory: Sendable {
    private let storeURL: URL?

    public init(storeURL: URL? = nil) {
        self.storeURL = storeURL
    }

    public func open() throws -> ModelContainer {
        let resolvedURL: URL
        if let storeURL {
            resolvedURL = storeURL
        } else {
            resolvedURL = try StoreDirectoryBuilder.storeURL(
                subdirectory: "KinetixLedger",
                filename: "ledger.store",
            )
        }

        let schema = Schema(versionedSchema: LedgerSchemaV1.self)
        let config = ModelConfiguration(
            "KinetixLedger",
            schema: schema,
            url: resolvedURL,
            cloudKitDatabase: .none,
        )

        return try ModelContainer(
            for: schema,
            migrationPlan: LedgerMigrationPlan.self,
            configurations: [config],
        )
    }
}
