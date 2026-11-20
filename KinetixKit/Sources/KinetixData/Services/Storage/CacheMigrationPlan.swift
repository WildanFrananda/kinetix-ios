import SwiftData

public enum CacheMigrationPlan: SchemaMigrationPlan {
    public static var schemas: [any VersionedSchema.Type] {
        return [CacheSchemaV1.self]
    }

    public static var stages: [MigrationStage] {
        return []
    }
}
