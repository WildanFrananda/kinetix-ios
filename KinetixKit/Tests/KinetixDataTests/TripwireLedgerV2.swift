import Foundation
import SwiftData

enum TripwireLedgerV2: VersionedSchema {
    static var versionIdentifier: Schema.Version {
        return Schema.Version(2, 0, 0)
    }

    static var models: [any PersistentModel.Type] {
        return [TripwireRow.self]
    }
}
