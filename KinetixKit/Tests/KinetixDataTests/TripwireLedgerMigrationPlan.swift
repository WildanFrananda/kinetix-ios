import SwiftData

enum TripwireLedgerMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        return [
            TripwireLedgerV1.self,
            TripwireLedgerV2.self,
        ]
    }

    static var stages: [MigrationStage] {
        return [
            MigrationStage.lightweight(
                fromVersion: TripwireLedgerV1.self,
                toVersion: TripwireLedgerV2.self,
            )
        ]
    }
}
