import Foundation
import KinetixDomain
import SwiftData

public struct SwiftDataCacheContainerFactory: Sendable {
    private let storeURL: URL?

    public init(storeURL: URL? = nil) {
        self.storeURL = storeURL
    }

    public func openOrRebuild() throws -> ModelContainer {
        let resolvedURL: URL
        if let storeURL {
            resolvedURL = storeURL
        } else {
            resolvedURL = try StoreDirectoryBuilder.storeURL(
                subdirectory: "KinetixCache",
                filename: "cache.store",
            )
        }

        let schema = Schema(versionedSchema: CacheSchemaV1.self)
        let config = ModelConfiguration(
            "KinetixCache",
            schema: schema,
            url: resolvedURL,
            cloudKitDatabase: .none,
        )

        do {
            return try ModelContainer(
                for: schema,
                migrationPlan: CacheMigrationPlan.self,
                configurations: [config],
            )
        } catch {
            removeStoreFiles(at: resolvedURL)
            return try ModelContainer(
                for: schema,
                migrationPlan: CacheMigrationPlan.self,
                configurations: [config],
            )
        }
    }

    private func removeStoreFiles(at url: URL) {
        let paths = [
            url.path,
            url.path + "-wal",
            url.path + "-shm",
        ]
        for path in paths {
            try? FileManager.default.removeItem(atPath: path)
        }
    }
}
