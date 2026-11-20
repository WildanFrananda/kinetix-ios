import SwiftData

public enum LedgerMigrationPlan: SchemaMigrationPlan {
    public static var schemas: [any VersionedSchema.Type] {
        return [LedgerSchemaV1.self]
    }

    public static var stages: [MigrationStage] {
        return []
    }
}
