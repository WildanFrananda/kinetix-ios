import Foundation
import SwiftData

enum TripwireLedgerV1: VersionedSchema {
    static var versionIdentifier: Schema.Version {
        return Schema.Version(1, 0, 0)
    }

    static var models: [any PersistentModel.Type] {
        return [TripwireRow.self]
    }
}
