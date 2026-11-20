import Foundation
import SwiftData

public enum CacheSchemaV1: VersionedSchema {
    public static var versionIdentifier: Schema.Version {
        return Schema.Version(1, 0, 0)
    }

    public static var models: [any PersistentModel.Type] {
        return [
            CachedProfileRecord.self,
            CachedCatalogPayloadRecord.self,
        ]
    }
}
